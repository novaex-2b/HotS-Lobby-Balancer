"""Bridge between the QML scene and balancer.py.

QML reads state through the Backend properties and the PlayersModel, and calls the
slots for every user action. All balancing and storage logic stays in balancer.py.
"""
import traceback
from pathlib import Path

from PySide6.QtCore import (Property, QAbstractListModel, QModelIndex, QObject, Qt, QUrl,
                            Signal, Slot)

import balancer as bal

MAX_NAMES_FILE_BYTES = 1_000_000


class PlayersModel(QAbstractListModel):
    """The lobby list. Rows are updated in place so the list keeps its scroll position."""

    ROLES = ["name", "satOut", "blue", "red", "devLabel", "lastPlayed", "status", "manual"]

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rows = []
        self._roles = {Qt.UserRole + 1 + i: r.encode() for i, r in enumerate(self.ROLES)}

    def roleNames(self):
        return self._roles

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._rows)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or not 0 <= index.row() < len(self._rows):
            return None
        key = self._roles.get(role)
        return self._rows[index.row()].get(key.decode()) if key else None

    def sync(self, rows):
        """Make the model match `rows` (sorted by name) with minimal insert/remove signals."""
        wanted = [r["name"] for r in rows]
        wanted_set = set(wanted)
        for i in range(len(self._rows) - 1, -1, -1):
            if self._rows[i]["name"] not in wanted_set:
                self.beginRemoveRows(QModelIndex(), i, i)
                del self._rows[i]
                self.endRemoveRows()
        for i, row in enumerate(rows):
            if i >= len(self._rows) or self._rows[i]["name"] != row["name"]:
                self.beginInsertRows(QModelIndex(), i, i)
                self._rows.insert(i, row)
                self.endInsertRows()
        self._rows = list(rows)
        if rows:
            self.dataChanged.emit(self.index(0), self.index(len(rows) - 1))


class Backend(QObject):
    changed = Signal()
    themeModeChanged = Signal()

    def __init__(self, db, theme_mode=0, parent=None):
        super().__init__(parent)
        self._db = db
        self._theme_mode = theme_mode    # 0 = follow the system, 1 = dark, 2 = light
        self._players = PlayersModel(self)
        self._state = {}
        self._manual = {}        # player name -> "blue" | "red", chosen by hand
        self._error = ""
        self._notice = ""
        self._refresh()

    # ---------------------------------------------------------------- state

    @staticmethod
    def _dev_label(dev):
        """Deviation from a fair Blue share as text: +1.1, -0.4, 0.0."""
        dev = dev or 0.0                       # turns -0.0 into 0.0
        return f"{dev:+.1f}" if dev else "0.0"

    def _refresh(self):
        self._state = bal.lobby_state(self._db)
        names = {p["name"] for p in self._state["players"]}
        self._manual = {n: s for n, s in self._manual.items() if n in names}
        self._players.sync([{
            "name": p["name"], "satOut": p["sat_out"], "blue": p["blue"], "red": p["red"],
            "devLabel": self._dev_label(p["dev"]), "lastPlayed": p["last_played"], "status": p["status"],
            "manual": self._manual.get(p["name"], ""),
        } for p in self._state["players"]])
        self.changed.emit()

    def _act(self, fn):
        """Run an action, show its message (or its error) in the banners, then refresh."""
        self._error = self._notice = ""
        ok = True
        try:
            message = fn()
            if message:
                self._notice = message
        except (ValueError, OSError) as e:      # includes FileNotFoundError and bad encodings
            self._error = str(e)
            ok = False
        except Exception as e:                  # a bug or a database problem: show it, don't hide it
            traceback.print_exc()
            self._error = f"Unexpected error: {e}"
            ok = False
        self._refresh()
        return ok

    def _count(self, side):
        return sum(1 for s in self._manual.values() if s == side)

    # ---------------------------------------------------------------- properties

    def _get_theme_mode(self):
        return self._theme_mode

    def _set_theme_mode(self, value):
        if value != self._theme_mode:
            self._theme_mode = value
            self.themeModeChanged.emit()

    themeMode = Property(int, _get_theme_mode, _set_theme_mode, notify=themeModeChanged)

    @Property(QObject, constant=True)
    def players(self):
        return self._players

    @Property(str, notify=changed)
    def warning(self):
        return self._state["warning"] or ""

    @Property(str, notify=changed)
    def error(self):
        return self._error

    @Property(str, notify=changed)
    def notice(self):
        return self._notice

    @Property(int, notify=changed)
    def matchNumber(self):
        return self._state["current"]["match_number"]

    @Property("QVariantList", notify=changed)
    def blueNames(self):
        return list(self._state["current"]["blue"])

    @Property("QVariantList", notify=changed)
    def redNames(self):
        return list(self._state["current"]["red"])

    @Property(int, notify=changed)
    def undoDepth(self):
        return self._state["undo_depth"]

    @Property(int, notify=changed)
    def needed(self):
        return self._state["needed"]

    @Property(int, notify=changed)
    def blueSlots(self):
        return self._state["blue_slots"]

    @Property(int, notify=changed)
    def redSlots(self):
        return self._state["red_slots"]

    @Property(int, notify=changed)
    def playerCount(self):
        return len(self._state["players"])

    @Property(int, notify=changed)
    def manualBlue(self):
        return self._count("blue")

    @Property(int, notify=changed)
    def manualRed(self):
        return self._count("red")

    # ---------------------------------------------------------------- actions

    @Slot(str, result=bool)
    def add(self, name):
        name = name.strip()

        def go():
            if not name:
                raise ValueError("Enter a name.")
            _, duplicates, too_long = bal.add_players(self._db, [name])
            if duplicates:
                raise ValueError(f"{name} is already in the lobby.")
            if too_long:
                raise ValueError(f"Names are limited to {bal.MAX_NAME_LEN} characters.")

        return self._act(go)

    @Slot(QUrl)
    def loadFile(self, url):
        """Add every name in a text file: one per line, blanks and #comments ignored."""
        def go():
            path = Path(url.toLocalFile())
            if path.stat().st_size > MAX_NAMES_FILE_BYTES:
                raise ValueError("That file is too large for a names list.")
            names = bal.parse_names(path.read_text(encoding="utf-8-sig"))
            if not names:
                raise ValueError("No names found in that file.")
            added, duplicates, too_long = bal.add_players(self._db, names)
            skipped = []
            if duplicates:
                skipped.append(f"{len(duplicates)} already in the lobby")
            if too_long:
                skipped.append(f"{len(too_long)} over {bal.MAX_NAME_LEN} characters")
            if not added:
                raise ValueError("No new names added: " + ", ".join(skipped) + ".")
            msg = f"Added {len(added)} player{'s' if len(added) != 1 else ''}"
            return msg + (f" (skipped {', '.join(skipped)})." if skipped else ".")

        self._act(go)

    @Slot(str)
    def remove(self, name):
        self._act(lambda: bal.remove_player(self._db, name))

    @Slot()
    def pick(self):
        def go():
            blue, red = bal.next_match(self._db)
            bal.record_match(self._db, blue, red)
            self._manual.clear()
        self._act(go)

    @Slot()
    def undo(self):
        def go():
            bal.undo_match(self._db)
            self._manual.clear()
        self._act(go)

    @Slot()
    def clearLobby(self):
        def go():
            bal.clear_lobby(self._db)
            self._manual.clear()
        self._act(go)

    @Slot(str, str)
    def toggleManual(self, name, side):
        if self._manual.get(name) == side:
            del self._manual[name]
        else:
            self._manual[name] = side
        self._refresh()

    @Slot()
    def clearManual(self):
        self._manual.clear()
        self._refresh()

    @Slot()
    def applyManual(self):
        def go():
            blue = [n for n, s in self._manual.items() if s == "blue"]
            red = [n for n, s in self._manual.items() if s == "red"]
            bal.manual_match(self._db, blue, red)
            self._manual.clear()
        self._act(go)
