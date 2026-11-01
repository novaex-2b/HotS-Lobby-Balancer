# Lobby Balancer (Qt Design Studio project)

The same lobby tool as the web version, as a Qt Quick desktop app styled with Everforest
(dark, or light when your system is in light mode).

## Run it

    pip install PySide6
    python main.py              # starts with an empty lobby
    python main.py --resume     # keep the lobby from the last run
    python main.py --theme light    # or dark / auto (default)

The lobby is stored in `lobby.db` (SQLite). Nothing else needs installing.

## Two ways to run it

- `python main.py` is the real app: the Python backend runs `balancer.py` and saves the lobby.
- Any other launch (for example Design Studio's Run button) has no Python process, so
  `App.qml` falls back to `Content/MockBackend.qml`. The window title says "(demo mode)".
  It follows the same rules, but everything stays in memory and nothing is saved. Loading a
  names file there needs `QML_XHR_ALLOW_FILE_READ=1`, which the project file already sets.
  If you change the balancing rules in `balancer.py`, mirror them in `MockBackend.qml`.

## Design it in Qt Design Studio

Open `LobbyBalancer.qmlproject`.

- `Content/Screen01.ui.qml` is the scene. It holds layout and styling only, and has sample
  data so it looks populated in the editor. Use this one for the design preview.
- Design Studio only allows function calls inside `Connections` objects in a `.ui.qml` file, so
  every button handler in `Screen01.ui.qml` is a `Connections` block near the top. Add new
  ones there.
- `Content/Card`, `FlatButton`, `SideButton`, `Banner`, `TeamCard`, `ThemedScrollBar`
  (`.ui.qml`) are the reusable components.
- `imports/LobbyBalancer/Constants.qml` holds every color (the Everforest palette) and
  size. Change `themeMode` there (0 system, 1 dark, 2 light) to preview a theme.
- `Content/App.qml`, `ConfirmDialog.qml` and `MockBackend.qml` are runtime-only glue. They
  connect the scene's properties and signals to the Python backend (`backend`, created in
  `main.py`) or, without Python, to the demo backend.

## How the pieces connect

    Screen01.ui.qml  --signals-->  App.qml  --calls-->  lobby_backend.py  -->  balancer.py (SQLite)
    Screen01.ui.qml  <-properties-  App.qml  <-reads---  lobby_backend.py

`balancer.py` is the same file as in the web version, so both front ends share one
lobby algorithm.
