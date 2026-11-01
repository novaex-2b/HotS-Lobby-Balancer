"""Run the Lobby Balancer desktop app (Qt Quick scene + balancer.py).

    pip install PySide6
    python main.py              starts with an empty lobby
    python main.py --resume     keeps the lobby from the last run
    python main.py --theme light|dark|auto

The lobby is stored in lobby.db (SQLite). Design the look in Design Studio by opening
LobbyBalancer.qmlproject; this script only supplies the data behind it.
"""
import argparse
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

import balancer as bal
from lobby_backend import Backend

ROOT = Path(__file__).parent


def build(db, theme_mode=0):
    """Create the QML engine and backend for a lobby database. Needs a QGuiApplication."""
    engine = QQmlApplicationEngine()
    engine.addImportPath(str(ROOT / "imports"))
    backend = Backend(db, theme_mode)
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(QUrl.fromLocalFile(str(ROOT / "Content" / "App.qml")))
    return engine, backend


def main():
    parser = argparse.ArgumentParser(description="Lobby Balancer")
    parser.add_argument("--resume", action="store_true",
                        help="keep the lobby from the last run instead of starting empty")
    parser.add_argument("--db", default=str(bal.DEFAULT_DB_FILE), help="SQLite database file")
    parser.add_argument("--theme", choices=["auto", "dark", "light"], default="auto")
    args, qt_args = parser.parse_known_args()

    QQuickStyle.setStyle("Basic")          # the scene styles every control itself
    app = QGuiApplication(sys.argv[:1] + qt_args)
    app.setApplicationName("Lobby Balancer")

    db = bal.connect(args.db)
    if not args.resume:
        bal.clear_lobby(db)                # the lobby starts empty

    engine, backend = build(db, {"auto": 0, "dark": 1, "light": 2}[args.theme])
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
