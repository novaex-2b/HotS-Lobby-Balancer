import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import LobbyBalancer

// Runtime glue: connects the Screen01 scene to a backend. When started with
// "python main.py", that is the Python backend (the "backend" context property).
// When started any other way, for example with Design Studio's Run button, there is no
// Python process, so the in-memory MockBackend is used instead (demo mode).
ApplicationWindow {
    id: window
    width: 1440
    height: 900
    minimumWidth: 1240      // narrower and the lobby table's columns no longer fit
    minimumHeight: 640
    visible: true
    title: qsTr("Lobby Balancer") + (demoMode ? qsTr(" (demo mode)") : "")
    color: Constants.page

    property var api: typeof backend !== "undefined" ? backend : demo
    readonly property bool demoMode: api === demo

    MockBackend {
        id: demo
    }

    // --theme on the command line (0 = system, 1 = dark, 2 = light)
    Binding {
        target: Constants
        property: "themeMode"
        value: window.api.themeMode
    }

    Screen01 {
        id: screen
        anchors.fill: parent

        warningText: window.api.warning
        errorText: window.api.error
        noticeText: window.api.notice
        matchNumber: window.api.matchNumber
        blueNames: window.api.blueNames
        redNames: window.api.redNames
        undoDepth: window.api.undoDepth
        needed: window.api.needed
        blueSlots: window.api.blueSlots
        redSlots: window.api.redSlots
        manualBlueCount: window.api.manualBlue
        manualRedCount: window.api.manualRed
        playersModel: window.api.players

        onPickRequested: window.api.pick()
        onUndoRequested: undoDialog.open()
        onClearRequested: clearDialog.open()
        onLoadFileRequested: fileDialog.open()
        onAddRequested: function (name) {
            if (window.api.add(name))
                screen.nameText = ""
        }
        onRemoveRequested: function (name) {
            window.api.remove(name)
        }
        onSideToggled: function (name, side) {
            window.api.toggleManual(name, side)
        }
        onManualApplyRequested: window.api.applyManual()
        onManualClearRequested: window.api.clearManual()
    }

    ConfirmDialog {
        id: undoDialog
        title: qsTr("Undo last match")
        message: qsTr("Undo match #%1? Stats and teams go back to how they were before it.").arg(window.api.matchNumber)
        confirmText: qsTr("Undo")
        onConfirmed: window.api.undo()
    }

    ConfirmDialog {
        id: clearDialog
        title: qsTr("Clear lobby")
        message: qsTr("Remove all %1 players and reset the match history? This can't be undone.").arg(window.api.playerCount)
        confirmText: qsTr("Clear lobby")
        onConfirmed: window.api.clearLobby()
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Load names")
        nameFilters: [qsTr("Text files (*.txt)"), qsTr("All files (*)")]
        onAccepted: window.api.loadFile(selectedFile)
    }
}
