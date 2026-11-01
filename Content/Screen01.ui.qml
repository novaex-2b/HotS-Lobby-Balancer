import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LobbyBalancer

// The lobby scene. It holds layout and styling only: data comes in through the
// properties below and user actions leave through the signals. App.qml connects
// both sides to the Python backend. The sample values make the scene look
// populated in Design Studio.
Rectangle {
    id: root
    width: 1440
    height: 900
    color: Constants.page

    // ---- data in
    property string warningText: ""
    property string errorText: ""
    property string noticeText: "Added 14 players."
    property int matchNumber: 4
    property var blueNames: ["Adishoy", "AnonTanuki", "Asassi", "BenceBob"]
    property var redNames: ["Chickmagnet", "Cryzzalis", "Daigoro", "Drakedragon", "Grizzfang"]
    property int undoDepth: 3
    property int needed: 9
    property int blueSlots: 4
    property int redSlots: 5
    property int manualBlueCount: 2
    property int manualRedCount: 1
    property var playersModel: sampleModel
    property alias nameText: nameField.text

    // ---- events out
    signal pickRequested
    signal undoRequested
    signal addRequested(string name)
    signal loadFileRequested
    signal clearRequested
    signal removeRequested(string name)
    signal sideToggled(string name, string side)
    signal manualApplyRequested
    signal manualClearRequested

    ListModel {
        id: sampleModel
        ListElement { name: "Adishoy";     satOut: 2; blue: 2; red: 0; devLabel: "+1.1";  lastPlayed: 4; status: "blue"; manual: "blue" }
        ListElement { name: "AnonTanuki";  satOut: 2; blue: 1; red: 1; devLabel: "+0.1";  lastPlayed: 4; status: "blue"; manual: "blue" }
        ListElement { name: "Asassi";      satOut: 2; blue: 2; red: 0; devLabel: "+1.1";  lastPlayed: 4; status: "blue"; manual: "" }
        ListElement { name: "BenceBob";    satOut: 2; blue: 1; red: 1; devLabel: "+0.1";  lastPlayed: 4; status: "blue"; manual: "" }
        ListElement { name: "Chickmagnet"; satOut: 2; blue: 1; red: 1; devLabel: "+0.1";  lastPlayed: 4; status: "red";  manual: "red" }
        ListElement { name: "Cryzzalis";   satOut: 2; blue: 1; red: 1; devLabel: "+0.1";  lastPlayed: 4; status: "red";  manual: "" }
        ListElement { name: "Daigoro";     satOut: 2; blue: 1; red: 1; devLabel: "+0.1";  lastPlayed: 4; status: "red";  manual: "" }
        ListElement { name: "Drakedragon"; satOut: 2; blue: 0; red: 2; devLabel: "-0.9"; lastPlayed: 4; status: "red";  manual: "" }
        ListElement { name: "Grizzfang";   satOut: 2; blue: 1; red: 1; devLabel: "+0.1";  lastPlayed: 4; status: "red";  manual: "" }
        ListElement { name: "IkkyLegend";  satOut: 3; blue: 0; red: 1; devLabel: "-0.4"; lastPlayed: 2; status: "out";  manual: "" }
        ListElement { name: "JohnWarcraft"; satOut: 3; blue: 0; red: 1; devLabel: "-0.4"; lastPlayed: 1; status: "out"; manual: "" }
        ListElement { name: "NobleShade";  satOut: 3; blue: 1; red: 0; devLabel: "+0.6";  lastPlayed: 3; status: "out";  manual: "" }
        ListElement { name: "Orangutan";   satOut: 3; blue: 0; red: 1; devLabel: "-0.4"; lastPlayed: 1; status: "out";  manual: "" }
        ListElement { name: "Rakko";       satOut: 3; blue: 1; red: 0; devLabel: "+0.6";  lastPlayed: 3; status: "out";  manual: "" }
    }

    // User actions leave the scene as signals. Function calls are only allowed inside
    // Connections objects in a .ui.qml file, so every handler lives here.
    Connections {
        target: pickButton
        function onClicked() { root.pickRequested() }
    }

    Connections {
        target: undoButton
        function onClicked() { root.undoRequested() }
    }

    Connections {
        target: addButton
        function onClicked() { root.addRequested(nameField.text) }
    }

    Connections {
        target: nameField
        function onAccepted() { root.addRequested(nameField.text) }
    }

    Connections {
        target: loadButton
        function onClicked() { root.loadFileRequested() }
    }

    Connections {
        target: clearButton
        function onClicked() { root.clearRequested() }
    }

    Connections {
        target: manualApplyButton
        function onClicked() { root.manualApplyRequested() }
    }

    Connections {
        target: manualClearButton
        function onClicked() { root.manualClearRequested() }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // ================= left: match and controls =================
        Flickable {
            id: sideFlick
            Layout.preferredWidth: 440
            Layout.minimumWidth: 340
            Layout.maximumWidth: 460
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: sideColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ThemedScrollBar {}

            ColumnLayout {
                id: sideColumn
                width: sideFlick.width
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 0

                        Text {
                            text: qsTr("Lobby Balancer")
                            color: Constants.text
                            font.pixelSize: Constants.fontTitle
                            font.bold: true
                        }

                        Text {
                            text: qsTr("Kanna hosts and always plays Blue")
                            color: Constants.subtle
                            font.pixelSize: Constants.fontBody - 1
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    FlatButton {
                        id: mapsButton
                        objectName: "mapsButton"
                        Layout.alignment: Qt.AlignTop
                        text: qsTr("ARAM maps")
                        implicitHeight: 28
                        font.pixelSize: Constants.fontSmall

                        ToolTip {
                            objectName: "mapsTip"
                            visible: mapsButton.hovered || mapsButton.activeFocus
                            x: mapsButton.width - width
                            y: mapsButton.height + 6
                            delay: 0
                            padding: 12
                            closePolicy: Popup.NoAutoClose

                            contentItem: ColumnLayout {
                                spacing: 2

                                Text {
                                    text: qsTr("ARAM maps")
                                    color: Constants.subtle
                                    font.pixelSize: Constants.fontCaption
                                    font.bold: true
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.8
                                    bottomPadding: 4
                                }

                                Repeater {
                                    model: ["Industrial District", "Braxis Outpost", "Silver City", "Lost Cavern"]

                                    Text {
                                        required property string modelData
                                        text: modelData
                                        color: Constants.text
                                        font.pixelSize: Constants.fontBody
                                    }
                                }
                            }

                            background: Rectangle {
                                color: Constants.raised
                                radius: 8
                                border.color: Constants.lineStrong
                                border.width: 1
                            }
                        }
                    }
                }

                Banner {
                    objectName: "warningBanner"
                    Layout.fillWidth: true
                    visible: root.warningText.length > 0
                    accent: Constants.yellow
                    text: root.warningText
                }

                Banner {
                    objectName: "errorBanner"
                    Layout.fillWidth: true
                    visible: root.errorText.length > 0
                    accent: Constants.red
                    text: root.errorText
                }

                Banner {
                    objectName: "noticeBanner"
                    Layout.fillWidth: true
                    visible: root.noticeText.length > 0
                    accent: Constants.aqua
                    text: root.noticeText
                }

                Card {
                    Layout.fillWidth: true
                    title: qsTr("Current match")
                    rightText: root.matchNumber > 0 ? qsTr("Match #") + root.matchNumber : ""

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        TeamCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            title: qsTr("Blue")
                            accent: Constants.blueTeam
                            names: root.blueNames
                            showHost: true
                            hasMatch: root.matchNumber > 0
                        }

                        TeamCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            title: qsTr("Red")
                            accent: Constants.redTeam
                            names: root.redNames
                            hasMatch: root.matchNumber > 0
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        FlatButton {
                            id: pickButton
                            objectName: "pickButton"
                            Layout.fillWidth: true
                            kind: "primary"
                            text: qsTr("Pick Match Players")
                            enabled: root.warningText.length === 0
                        }

                        FlatButton {
                            id: undoButton
                            objectName: "undoButton"
                            text: qsTr("Undo")
                            enabled: root.undoDepth > 0
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    title: qsTr("Add players")

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: nameField
                            objectName: "nameField"
                            Layout.fillWidth: true
                            implicitHeight: 34
                            placeholderText: qsTr("Player name")
                            maximumLength: 40
                            leftPadding: 10
                            rightPadding: 10
                            topPadding: 0
                            bottomPadding: 0
                            color: Constants.text
                            placeholderTextColor: Constants.subtle
                            selectionColor: Constants.accent
                            selectedTextColor: Constants.accentInk
                            font.pixelSize: Constants.fontBody
                            verticalAlignment: TextInput.AlignVCenter

                            background: Rectangle {
                                radius: Constants.radiusControl
                                color: Constants.page
                                border.width: 1
                                border.color: nameField.activeFocus ? Constants.accent : Constants.lineStrong
                            }
                        }

                        FlatButton {
                            id: addButton
                            objectName: "addButton"
                            text: qsTr("Add")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        FlatButton {
                            id: loadButton
                            objectName: "loadButton"
                            text: qsTr("Load names from file…")
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        FlatButton {
                            id: clearButton
                            objectName: "clearButton"
                            kind: "danger"
                            text: qsTr("Clear lobby")
                            enabled: playerList.count > 0
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("A names file has one name per line. Blank lines and lines starting with # are ignored.")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontSmall
                        wrapMode: Text.WordWrap
                    }
                }

                Card {
                    Layout.fillWidth: true
                    title: qsTr("Manual teams")

                    Row {
                        spacing: 5

                        Text {
                            text: qsTr("Blue")
                            color: Constants.text
                            font.pixelSize: Constants.fontBody
                        }

                        Text {
                            objectName: "manualBlueText"
                            text: root.manualBlueCount + "/" + root.blueSlots
                            color: root.manualBlueCount > root.blueSlots ? Constants.redText : Constants.text
                            font.pixelSize: Constants.fontBody
                            font.bold: root.manualBlueCount > root.blueSlots
                        }

                        Text {
                            text: qsTr("(plus Kanna) ·")
                            color: Constants.text
                            font.pixelSize: Constants.fontBody
                        }

                        Text {
                            text: qsTr("Red")
                            color: Constants.text
                            font.pixelSize: Constants.fontBody
                        }

                        Text {
                            objectName: "manualRedText"
                            text: root.manualRedCount + "/" + root.redSlots
                            color: root.manualRedCount > root.redSlots ? Constants.redText : Constants.text
                            font.pixelSize: Constants.fontBody
                            font.bold: root.manualRedCount > root.redSlots
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Pick B or R on each player in the lobby list. This records a match just like Pick Match Players.")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontSmall
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        FlatButton {
                            id: manualApplyButton
                            objectName: "manualApplyButton"
                            text: qsTr("Set teams manually")
                            enabled: root.manualBlueCount === root.blueSlots
                                     && root.manualRedCount === root.redSlots
                        }

                        FlatButton {
                            id: manualClearButton
                            objectName: "manualClearButton"
                            kind: "ghost"
                            text: qsTr("Clear selections")
                            enabled: root.manualBlueCount + root.manualRedCount > 0
                        }
                    }
                }
            }
        }

        // ================= right: the whole lobby =================
        Rectangle {
            id: lobbyPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Constants.surface
            radius: Constants.radiusCard
            border.color: Constants.line
            border.width: 1
            clip: true

            // column widths shared by the header row and every player row
            readonly property int wStatus: 130
            readonly property int wSat: 64
            readonly property int wBlue: 56
            readonly property int wRed: 50
            readonly property int wDev: 60
            readonly property int wLast: 52
            readonly property int wTeam: 70
            readonly property int wRemove: 76

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16

                    Text {
                        text: qsTr("Lobby")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontSmall
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.8
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        objectName: "countText"
                        text: playerList.count + (playerList.count === 1 ? qsTr(" player") : qsTr(" players"))
                              + " · " + root.needed + qsTr(" needed besides Kanna")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontSmall
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Constants.line
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 80
                        text: qsTr("Player")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontCaption
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.5
                    }
                    Text {
                        Layout.preferredWidth: lobbyPanel.wStatus
                        text: qsTr("This match")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontCaption
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.5
                    }
                    Text {
                        Layout.preferredWidth: lobbyPanel.wSat
                        horizontalAlignment: Text.AlignRight
                        text: qsTr("Sat out")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontCaption
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.5
                    }
                    Text {
                        Layout.preferredWidth: lobbyPanel.wBlue
                        horizontalAlignment: Text.AlignRight
                        text: qsTr("Blue")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontCaption
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.5
                    }
                    Text {
                        Layout.preferredWidth: lobbyPanel.wRed
                        horizontalAlignment: Text.AlignRight
                        text: qsTr("Red")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontCaption
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.5
                    }
                    Text {
                        Layout.preferredWidth: lobbyPanel.wDev
                        horizontalAlignment: Text.AlignRight
                        text: qsTr("Dev")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontCaption
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.5
                    }
                    Text {
                        Layout.preferredWidth: lobbyPanel.wLast
                        horizontalAlignment: Text.AlignRight
                        text: qsTr("Last")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontCaption
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.5
                    }
                    Text {
                        Layout.preferredWidth: lobbyPanel.wTeam
                        Layout.leftMargin: 8
                        text: qsTr("Team")
                        color: Constants.subtle
                        font.pixelSize: Constants.fontCaption
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.5
                    }
                    Item {
                        Layout.preferredWidth: lobbyPanel.wRemove
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Constants.line
                }

                ListView {
                    id: playerList
                    objectName: "playerList"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.playersModel
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ThemedScrollBar {}

                    delegate: Rectangle {
                        id: row
                        width: ListView.view.width
                        height: 32
                        color: "transparent"

                        readonly property string statusLabel: root.matchNumber <= 0 ? "–"
                            : model.status === "blue" ? qsTr("Blue")
                            : model.status === "red" ? qsTr("Red") : qsTr("Sitting out")

                        Rectangle {
                            anchors.fill: parent
                            color: rowHover.containsMouse ? Constants.raised : "transparent"
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Constants.line
                        }

                        Connections {
                            target: blueSideButton
                            function onClicked() { root.sideToggled(model.name, "blue") }
                        }

                        Connections {
                            target: redSideButton
                            function onClicked() { root.sideToggled(model.name, "red") }
                        }

                        Connections {
                            target: removeRowButton
                            function onClicked() { root.removeRequested(model.name) }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 80
                                text: model.name
                                color: Constants.text
                                font.pixelSize: Constants.fontTable
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.preferredWidth: lobbyPanel.wStatus
                                spacing: 6

                                Rectangle {
                                    visible: root.matchNumber > 0
                                    width: 9
                                    height: 9
                                    radius: 4.5
                                    color: model.status === "blue" ? Constants.blueTeam
                                           : model.status === "red" ? Constants.redTeam : Constants.muted
                                }

                                Text {
                                    text: row.statusLabel
                                    color: Constants.text
                                    font.pixelSize: Constants.fontTable
                                }
                            }

                            Text {
                                Layout.preferredWidth: lobbyPanel.wSat
                                horizontalAlignment: Text.AlignRight
                                text: model.satOut
                                color: Constants.text
                                font.pixelSize: Constants.fontTable
                            }
                            Text {
                                Layout.preferredWidth: lobbyPanel.wBlue
                                horizontalAlignment: Text.AlignRight
                                text: model.blue
                                color: Constants.text
                                font.pixelSize: Constants.fontTable
                            }
                            Text {
                                Layout.preferredWidth: lobbyPanel.wRed
                                horizontalAlignment: Text.AlignRight
                                text: model.red
                                color: Constants.text
                                font.pixelSize: Constants.fontTable
                            }
                            Text {
                                Layout.preferredWidth: lobbyPanel.wDev
                                horizontalAlignment: Text.AlignRight
                                text: model.devLabel
                                color: Constants.text
                                font.pixelSize: Constants.fontTable
                            }
                            Text {
                                Layout.preferredWidth: lobbyPanel.wLast
                                horizontalAlignment: Text.AlignRight
                                text: model.lastPlayed > 0 ? model.lastPlayed : "–"
                                color: Constants.text
                                font.pixelSize: Constants.fontTable
                            }

                            RowLayout {
                                Layout.preferredWidth: lobbyPanel.wTeam
                                Layout.leftMargin: 8
                                spacing: 4

                                SideButton {
                                    id: blueSideButton
                                    objectName: "blueSide"
                                    text: "B"
                                    accent: Constants.blueTeam
                                    selected: model.manual === "blue"
                                }

                                SideButton {
                                    id: redSideButton
                                    objectName: "redSide"
                                    text: "R"
                                    accent: Constants.redTeam
                                    selected: model.manual === "red"
                                }
                            }

                            FlatButton {
                                id: removeRowButton
                                objectName: "removeButton"
                                Layout.preferredWidth: lobbyPanel.wRemove
                                kind: "ghost"
                                text: qsTr("Remove")
                            }
                        }
                    }
                }
            }

            Text {
                objectName: "emptyText"
                anchors.centerIn: parent
                width: parent.width - 64
                visible: playerList.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: qsTr("The lobby is empty. Add names with the form on the left or load a text file.")
                color: Constants.subtle
                font.pixelSize: Constants.fontBody
            }
        }
    }
}
