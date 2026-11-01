import QtQuick

// Stand-in for the Python backend (lobby_backend.py), used when the app is started
// without Python, for example with Design Studio's Run button. It applies the same
// rules as balancer.py, but keeps everything in memory, so nothing is saved.
// It exposes the same properties and functions, so App.qml can use either one.
QtObject {
    id: root

    readonly property int needed: 9
    readonly property int blueSlots: 4
    readonly property int redSlots: 5

    property string error: ""
    property string notice: qsTr("Demo mode: not connected to the Python backend, so nothing is saved. Run python main.py for the real app.")
    property int matchNumber: 0
    property var blueNames: []
    property var redNames: []
    property int undoDepth: 0
    property int playerCount: 0
    property int manualBlue: 0
    property int manualRed: 0
    property int themeMode: 0
    readonly property string warning: playerCount < needed
                                      ? qsTr("Not enough players: a match needs %1 besides Kanna, and the lobby has %2 (%3 more needed).")
                                        .arg(needed).arg(playerCount).arg(needed - playerCount)
                                      : ""
    property ListModel players: ListModel {}

    // private state
    property var _roster: []        // [{name, satOut, blue, red, last}]
    property var _manual: ({})      // name -> "blue" | "red"
    property var _history: []       // snapshots for undo, newest last

    // ---------------------------------------------------------------- helpers

    function _has(obj, key) {
        return Object.prototype.hasOwnProperty.call(obj, key)
    }

    function _find(name) {
        var key = String(name).toLowerCase()
        for (var i = 0; i < _roster.length; i++)
            if (_roster[i].name.toLowerCase() === key)
                return _roster[i]
        return null
    }

    function _shuffle(list) {
        for (var i = list.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1))
            var t = list[i]; list[i] = list[j]; list[j] = t
        }
        return list
    }

    function _devLabel(dev) {
        var r = Math.round(dev * 10) / 10
        return r === 0 ? "0.0" : (r > 0 ? "+" : "") + r.toFixed(1)
    }

    function _countManual(side) {
        var c = 0
        for (var k in _manual)
            if (_manual[k] === side)
                c++
        return c
    }

    function _begin() {
        error = ""
        notice = ""
    }

    function _fail(message) {
        error = message
        _refresh()
        return false
    }

    function _refresh() {
        for (var k in _manual)
            if (!_find(k))
                delete _manual[k]
        var side = ({})
        blueNames.forEach(function (n) { side[n.toLowerCase()] = "blue" })
        redNames.forEach(function (n) { side[n.toLowerCase()] = "red" })

        var sorted = _roster.slice().sort(function (a, b) {
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
        })
        players.clear()
        sorted.forEach(function (p) {
            var key = p.name.toLowerCase()
            players.append({
                name: p.name, satOut: p.satOut, blue: p.blue, red: p.red,
                devLabel: _devLabel(p.blue - (p.blue + p.red) * blueSlots / needed),
                lastPlayed: p.last,
                status: _has(side, key) ? side[key] : "out",
                manual: _has(_manual, p.name) ? _manual[p.name] : ""
            })
        })
        playerCount = sorted.length
        manualBlue = _countManual("blue")
        manualRed = _countManual("red")
    }

    // One name per line; blank lines, #comments and repeats (any case) are ignored.
    function _parseNames(text) {
        if (text.length > 0 && text.charCodeAt(0) === 0xFEFF)
            text = text.substring(1)
        var names = [], lowers = []
        text.split(/\r?\n/).forEach(function (line) {
            var n = line.trim()
            if (n !== "" && n.charAt(0) !== "#" && lowers.indexOf(n.toLowerCase()) < 0) {
                lowers.push(n.toLowerCase())
                names.push(n)
            }
        })
        return names
    }

    // New players start at the lobby average so they are not over- or under-prioritized.
    function _addNames(names) {
        var n = Math.max(_roster.length, 1)
        var avg = function (field) {
            var sum = 0
            _roster.forEach(function (p) { sum += p[field] })
            return Math.round(sum / n)
        }
        var start = { satOut: avg("satOut"), blue: avg("blue"), red: avg("red") }
        var added = [], duplicates = [], tooLong = []
        names.forEach(function (name) {
            if (_find(name))
                duplicates.push(name)
            else if (name.length > 40)
                tooLong.push(name)
            else {
                _roster.push({ name: name, satOut: start.satOut, blue: start.blue, red: start.red, last: 0 })
                added.push(name)
            }
        })
        return { added: added, duplicates: duplicates, tooLong: tooLong }
    }

    function _readFile(url) {
        try {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", url.toString(), false)
            xhr.send()
            if (xhr.status !== 0 && xhr.status !== 200)
                return null
            return xhr.responseText === "" ? null : xhr.responseText
        } catch (e) {
            return null     // file reading is disabled, or the file can't be opened
        }
    }

    function _record(blue, red) {
        _history.push({
            match: matchNumber, blue: blueNames, red: redNames,
            roster: JSON.parse(JSON.stringify(_roster))
        })
        if (_history.length > 20)
            _history.shift()
        var m = matchNumber + 1
        _roster.forEach(function (p) {
            if (blue.indexOf(p.name) >= 0) { p.blue++; p.last = m }
            else if (red.indexOf(p.name) >= 0) { p.red++; p.last = m }
            else p.satOut++
        })
        matchNumber = m
        blueNames = blue
        redNames = red
        undoDepth = _history.length
        _manual = ({})
    }

    // ---------------------------------------------------------------- actions

    function add(name) {
        _begin()
        name = String(name).trim()
        if (name === "")
            return _fail(qsTr("Enter a name."))
        var r = _addNames([name])
        if (r.duplicates.length > 0)
            return _fail(qsTr("%1 is already in the lobby.").arg(name))
        if (r.tooLong.length > 0)
            return _fail(qsTr("Names are limited to 40 characters."))
        _refresh()
        return true
    }

    function loadFile(url) {
        _begin()
        var text = _readFile(url)
        if (text === null)
            return _fail(qsTr("Could not read that file. In demo mode, file loading needs the environment variable QML_XHR_ALLOW_FILE_READ=1 (the project file sets it)."))
        var names = _parseNames(text)
        if (names.length === 0)
            return _fail(qsTr("No names found in that file."))
        var r = _addNames(names)
        var skipped = []
        if (r.duplicates.length > 0)
            skipped.push(qsTr("%1 already in the lobby").arg(r.duplicates.length))
        if (r.tooLong.length > 0)
            skipped.push(qsTr("%1 over 40 characters").arg(r.tooLong.length))
        if (r.added.length === 0)
            return _fail(qsTr("No new names added: ") + skipped.join(", ") + ".")
        notice = qsTr("Added %1 player(s)").arg(r.added.length)
                 + (skipped.length > 0 ? " (" + qsTr("skipped ") + skipped.join(", ") + ")." : ".")
        _refresh()
        return true
    }

    function remove(name) {
        _begin()
        var p = _find(name)
        if (!p)
            return _fail(qsTr("%1 is not in the lobby.").arg(name))
        _roster.splice(_roster.indexOf(p), 1)
        _refresh()
    }

    function pick() {
        _begin()
        if (_roster.length < needed)
            return _fail(qsTr("Need %1 active players besides Kanna, have %2").arg(needed).arg(_roster.length))
        // Who plays: most matches sat out first, then played longest ago; ties are random.
        var pool = _shuffle(_roster.slice())
        pool.sort(function (a, b) { return (b.satOut - a.satOut) || (a.last - b.last) })
        // Teams: the most Red-heavy players (lowest blue - red) get the Blue slots.
        var chosen = _shuffle(pool.slice(0, needed))
        chosen.sort(function (a, b) { return (a.blue - a.red) - (b.blue - b.red) })
        var names = chosen.map(function (p) { return p.name })
        _record(names.slice(0, blueSlots), names.slice(blueSlots))
        _refresh()
    }

    function undo() {
        _begin()
        if (_history.length === 0)
            return _fail(qsTr("Nothing to undo."))
        var snap = _history.pop()
        // Only the match counters are restored; players who joined or left since stay as they are.
        snap.roster.forEach(function (s) {
            var p = _find(s.name)
            if (p) { p.satOut = s.satOut; p.blue = s.blue; p.red = s.red; p.last = s.last }
        })
        matchNumber = snap.match
        blueNames = snap.blue
        redNames = snap.red
        undoDepth = _history.length
        _manual = ({})
        _refresh()
    }

    function clearLobby() {
        _begin()
        _roster = []
        _history = []
        _manual = ({})
        matchNumber = 0
        blueNames = []
        redNames = []
        undoDepth = 0
        _refresh()
    }

    function toggleManual(name, side) {
        if (_has(_manual, name) && _manual[name] === side)
            delete _manual[name]
        else
            _manual[name] = side
        for (var i = 0; i < players.count; i++)
            if (players.get(i).name === name)
                players.setProperty(i, "manual", _has(_manual, name) ? _manual[name] : "")
        manualBlue = _countManual("blue")
        manualRed = _countManual("red")
    }

    function clearManual() {
        _manual = ({})
        _refresh()
    }

    function applyManual() {
        _begin()
        var blue = [], red = []
        for (var k in _manual)
            (_manual[k] === "blue" ? blue : red).push(k)
        if (blue.length !== blueSlots || red.length !== redSlots)
            return _fail(qsTr("Pick exactly %1 players for Blue (Kanna is the %2th) and %3 for Red.")
                         .arg(blueSlots).arg(blueSlots + 1).arg(redSlots))
        _record(blue, red)
        _refresh()
    }
}
