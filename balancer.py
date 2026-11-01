"""Lobby balancer for a Heroes of the Storm custom lobby.

Goals: every player gets the same amount of playing time and the same number of
games on Blue and Red. Kanna (the host) always plays, always on Blue.

Storage is SQLite from the standard library, so there is no database package to install.
"""
import json
import random
import sqlite3
from pathlib import Path

HERE = Path(__file__).parent
DEFAULT_NAMES_FILE = HERE / "names.txt"
DEFAULT_DB_FILE = HERE / "lobby.db"

TEAM_SIZE = 5
SLOTS = 2 * TEAM_SIZE - 1      # 9 players besides Kanna
BLUE_SLOTS = TEAM_SIZE - 1     # Kanna fills the 5th Blue slot
RED_SLOTS = SLOTS - BLUE_SLOTS
MAX_NAME_LEN = 40
MAX_UNDO = 20
COUNTERS = ("sat_out", "blue", "red", "last_played")

SCHEMA = """
CREATE TABLE IF NOT EXISTS kamos (
    name        TEXT PRIMARY KEY COLLATE NOCASE,   -- "zipli" and "Zipli" are the same player
    sat_out     INTEGER NOT NULL DEFAULT 0,        -- matches sat out since joining
    blue        INTEGER NOT NULL DEFAULT 0,
    red         INTEGER NOT NULL DEFAULT 0,
    last_played INTEGER NOT NULL DEFAULT 0,        -- match number, 0 = never
    active      INTEGER NOT NULL DEFAULT 1         -- 0 = left the lobby (history kept)
);
CREATE TABLE IF NOT EXISTS lobby (
    id           INTEGER PRIMARY KEY CHECK (id = 1),
    match_number INTEGER NOT NULL DEFAULT 0,
    blue         TEXT NOT NULL DEFAULT '[]',       -- JSON list: current Blue (besides Kanna)
    red          TEXT NOT NULL DEFAULT '[]'
);
CREATE TABLE IF NOT EXISTS history (               -- undo stack, newest = highest id
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    snapshot TEXT NOT NULL
);
INSERT OR IGNORE INTO lobby (id) VALUES (1);
"""


def connect(path=DEFAULT_DB_FILE):
    """Open (creating if needed) the lobby database. Use ":memory:" for a throwaway one."""
    db = sqlite3.connect(str(path), check_same_thread=False)  # callers serialize access
    db.row_factory = sqlite3.Row
    db.executescript(SCHEMA)
    return db


def get_players(db):
    return [dict(r) for r in db.execute("SELECT * FROM kamos WHERE active = 1")]


# ---------------------------------------------------------------- names

def parse_names(text):
    """One name per line. Blank lines, #comments and repeated names (any case) are ignored."""
    names, seen = [], set()
    for line in text.lstrip("﻿").splitlines():     # some editors add a BOM
        name = line.strip()
        if name and not name.startswith("#") and name.lower() not in seen:
            seen.add(name.lower())
            names.append(name)
    return names


def load_names(path=DEFAULT_NAMES_FILE, limit=None, min_players=SLOTS):
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"Names file not found: {path}")
    names = parse_names(path.read_text(encoding="utf-8-sig"))
    if limit is not None:
        names = names[:limit]
    if len(names) < min_players:
        raise ValueError(f"Need at least {min_players} names, found {len(names)} in {path}")
    return names


# ---------------------------------------------------------------- lobby changes

def add_players(db, names):
    """Add names to the lobby. New and returning players start at the lobby's current
    average, so they aren't prioritized (or penalized) for matches they weren't here for.
    Returns (added, already_in_lobby, too_long)."""
    rows = get_players(db)
    in_lobby = {p["name"].lower() for p in rows}
    n = max(len(rows), 1)
    avg = {f: round(sum(p[f] for p in rows) / n) for f in ("sat_out", "blue", "red")}

    added, duplicates, too_long = [], [], []
    with db:
        for name in names:
            if name.lower() in in_lobby:
                duplicates.append(name)
            elif len(name) > MAX_NAME_LEN:
                too_long.append(name)
            else:
                db.execute(
                    "INSERT INTO kamos (name, sat_out, blue, red, last_played, active) "
                    "VALUES (?, ?, ?, ?, 0, 1) "
                    "ON CONFLICT(name) DO UPDATE SET sat_out = excluded.sat_out, "
                    "blue = excluded.blue, red = excluded.red, last_played = 0, active = 1",
                    (name, avg["sat_out"], avg["blue"], avg["red"]))
                in_lobby.add(name.lower())
                added.append(name)
    return added, duplicates, too_long


def remove_player(db, name):
    """Take a player out of the lobby but keep their record."""
    with db:
        cur = db.execute("UPDATE kamos SET active = 0 WHERE name = ? AND active = 1", (name,))
    if cur.rowcount == 0:
        raise ValueError(f"{name} is not in the lobby.")


def clear_lobby(db):
    """Fresh start: delete every player and reset the match number, teams and undo history."""
    with db:
        db.execute("DELETE FROM kamos")
        db.execute("DELETE FROM history")
        db.execute("UPDATE lobby SET match_number = 0, blue = '[]', red = '[]' WHERE id = 1")


# ---------------------------------------------------------------- matches

def next_match(db):
    """Propose (blue, red) name lists for the next match. Writes nothing."""
    players = get_players(db)
    if len(players) < SLOTS:
        raise ValueError(f"Need {SLOTS} active players besides Kanna, have {len(players)}")

    # Who plays: most matches sat out first, then played longest ago.
    # Shuffling first makes any remaining ties random (sort is stable).
    random.shuffle(players)
    players.sort(key=lambda p: (-p["sat_out"], p["last_played"]))
    chosen = players[:SLOTS]

    # Teams: the most Red-heavy players (lowest blue - red) get the Blue slots.
    random.shuffle(chosen)
    chosen.sort(key=lambda p: p["blue"] - p["red"])
    return ([p["name"] for p in chosen[:BLUE_SLOTS]],
            [p["name"] for p in chosen[BLUE_SLOTS:]])


def record_match(db, blue, red):
    """Commit a match atomically and save an undo snapshot. Either everything is
    written or, if anything fails, nothing is. Returns the match number."""
    played = list(blue) + list(red)
    marks = lambda names: ",".join("?" * len(names))
    with db:  # one transaction: commits on success, rolls back on any exception
        lobby = db.execute("SELECT * FROM lobby WHERE id = 1").fetchone()
        snapshot = {
            "match_number": lobby["match_number"],
            "blue": json.loads(lobby["blue"]),
            "red": json.loads(lobby["red"]),
            "players": [{"name": p["name"], **{k: p[k] for k in COUNTERS}}
                        for p in get_players(db)],
        }
        m = lobby["match_number"] + 1
        db.execute(f"UPDATE kamos SET blue = blue + 1, last_played = ? "
                   f"WHERE name IN ({marks(blue)})", [m, *blue])
        db.execute(f"UPDATE kamos SET red = red + 1, last_played = ? "
                   f"WHERE name IN ({marks(red)})", [m, *red])
        db.execute(f"UPDATE kamos SET sat_out = sat_out + 1 "
                   f"WHERE active = 1 AND name NOT IN ({marks(played)})", played)
        db.execute("UPDATE lobby SET match_number = ?, blue = ?, red = ? WHERE id = 1",
                   (m, json.dumps(list(blue)), json.dumps(list(red))))
        db.execute("INSERT INTO history (snapshot) VALUES (?)", (json.dumps(snapshot),))
        db.execute("DELETE FROM history WHERE id NOT IN "
                   "(SELECT id FROM history ORDER BY id DESC LIMIT ?)", (MAX_UNDO,))
    return m


def manual_match(db, blue, red):
    """Record a match with hand-picked teams (Kanna is the extra Blue player)."""
    if len(blue) != BLUE_SLOTS or len(red) != RED_SLOTS:
        raise ValueError(f"Pick exactly {BLUE_SLOTS} players for Blue (Kanna is the "
                         f"{BLUE_SLOTS + 1}th) and {RED_SLOTS} for Red.")
    keys = [n.lower() for n in list(blue) + list(red)]
    if len(set(keys)) != len(keys):
        raise ValueError("A player can't be on both teams.")
    canon = {p["name"].lower(): p["name"] for p in get_players(db)}
    missing = [n for n in list(blue) + list(red) if n.lower() not in canon]
    if missing:
        raise ValueError(f"Not in the lobby: {', '.join(missing)}")
    return record_match(db, [canon[n.lower()] for n in blue], [canon[n.lower()] for n in red])


def undo_match(db):
    """Reverse the most recent match. Only the match counters are restored; players who
    joined or left since then are left as they are."""
    with db:
        row = db.execute("SELECT id, snapshot FROM history ORDER BY id DESC LIMIT 1").fetchone()
        if row is None:
            raise ValueError("Nothing to undo.")
        snap = json.loads(row["snapshot"])
        for p in snap["players"]:
            db.execute("UPDATE kamos SET sat_out = ?, blue = ?, red = ?, last_played = ? "
                       "WHERE name = ?", (p["sat_out"], p["blue"], p["red"], p["last_played"], p["name"]))
        db.execute("UPDATE lobby SET match_number = ?, blue = ?, red = ? WHERE id = 1",
                   (snap["match_number"], json.dumps(snap["blue"]), json.dumps(snap["red"])))
        db.execute("DELETE FROM history WHERE id = ?", (row["id"],))


def lobby_state(db):
    """Everything the web page shows, as plain JSON-able data."""
    lobby = db.execute("SELECT * FROM lobby WHERE id = 1").fetchone()
    blue, red = json.loads(lobby["blue"]), json.loads(lobby["red"])
    side = {n.lower(): "blue" for n in blue}
    side.update({n.lower(): "red" for n in red})

    players = []
    for p in sorted(get_players(db), key=lambda p: p["name"].lower()):
        games = p["blue"] + p["red"]
        players.append({
            "name": p["name"],
            **{k: p[k] for k in COUNTERS},
            "dev": round(p["blue"] - games * BLUE_SLOTS / SLOTS, 1),   # 0 = perfectly fair
            "status": side.get(p["name"].lower(), "out"),
        })

    have = len(players)
    warning = None
    if have < SLOTS:
        warning = (f"Not enough players: a match needs {SLOTS} besides Kanna, "
                   f"and the lobby has {have} ({SLOTS - have} more needed).")
    return {
        "players": players,
        "needed": SLOTS,
        "blue_slots": BLUE_SLOTS,
        "red_slots": RED_SLOTS,
        "warning": warning,
        "undo_depth": db.execute("SELECT COUNT(*) FROM history").fetchone()[0],
        "current": {"match_number": lobby["match_number"], "blue": blue, "red": red},
    }


# ---------------------------------------------------------------- simulation

def init_test_data(db, names_file=DEFAULT_NAMES_FILE, limit=None):
    """Replace the lobby with the names from a file, every counter at zero."""
    clear_lobby(db)
    add_players(db, load_names(names_file, limit))


def simulate_lobby(db, matches=10, names_file=DEFAULT_NAMES_FILE, limit=None):
    """Run a simulated lobby, printing teams and pre-match stats for each match."""
    init_test_data(db, names_file, limit)

    header = (f"  {'Player':<14}{'sat_out':>7}{'blue':>6}{'red':>5}{'b-r':>6}{'last':>6}"
              f"{'min':>5}{'max':>5}{'avg':>6}")

    played_in = {}                         # name -> match numbers the player has played in

    def gap_stats(name):
        """Min/max/avg matches sat out between two consecutive games the player played.
        Needs at least two games; the wait before a first game doesn't count."""
        h = played_in.get(name, [])
        gaps = [b - a - 1 for a, b in zip(h, h[1:])]
        if not gaps:
            return f"{'-':>5}{'-':>5}{'-':>6}"
        return f"{min(gaps):>5}{max(gaps):>5}{sum(gaps) / len(gaps):>6.1f}"

    def fmt(p):
        return (f"  {p['name']:<14}{p['sat_out']:>7}{p['blue']:>6}{p['red']:>5}"
                f"{p['blue'] - p['red']:>6}{p['last_played']:>6}{gap_stats(p['name'])}")

    def fetch():
        return {p["name"]: p for p in get_players(db)}

    for i in range(1, matches + 1):
        blue, red = next_match(db)
        stats = fetch()                    # snapshot before the match is recorded
        benched = sorted(n for n in stats if n not in blue + red)

        print(f"\n=== Match {i} ===")
        print("BLUE")
        print(header)
        print(f"  {'Kanna':<14}{'(host, always Blue)':>30}")
        for name in blue:
            print(fmt(stats[name]))
        print("RED")
        print(header)
        for name in red:
            print(fmt(stats[name]))
        print("SITTING OUT")
        print(header)
        for name in benched:
            print(fmt(stats[name]))

        m = record_match(db, blue, red)
        for name in blue + red:
            played_in.setdefault(name, []).append(m)

    print(f"\n=== Final stats after {matches} matches ===")
    print(header)
    final = fetch()
    for name in sorted(final):
        print(fmt(final[name]))


def main():
    db = connect(":memory:")   # throwaway database: simulations never touch the real lobby
    simulate_lobby(db, matches=70, names_file=HERE / "hots.txt")


if __name__ == "__main__":
    main()
