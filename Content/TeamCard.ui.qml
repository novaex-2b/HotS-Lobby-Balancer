import QtQuick
import QtQuick.Layouts
import LobbyBalancer

// One team of the current match. "names" excludes Kanna, who is shown as the host line.
Rectangle {
    id: root

    property string title: "Blue"
    property color accent: Constants.blueTeam
    property var names: []
    property bool showHost: false
    property bool hasMatch: true

    implicitWidth: 190
    implicitHeight: col.implicitHeight + 26 > 168 ? col.implicitHeight + 26 : 168
    color: Constants.page
    radius: 8
    border.color: Constants.line
    border.width: 1

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        height: 3
        radius: 1.5
        color: root.accent
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 14
        spacing: 2

        Text {
            text: root.title
            color: Constants.text
            font.pixelSize: Constants.fontSmall
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.8
            bottomPadding: 4
        }

        Text {
            visible: root.hasMatch && root.showHost
            Layout.fillWidth: true
            text: qsTr("Kanna (host)")
            color: Constants.text
            font.pixelSize: Constants.fontBody
            font.bold: true
            elide: Text.ElideRight
        }

        Repeater {
            model: root.hasMatch ? root.names : []

            Text {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                color: Constants.text
                font.pixelSize: Constants.fontBody
                elide: Text.ElideRight
            }
        }

        Text {
            visible: !root.hasMatch
            text: qsTr("No match yet")
            color: Constants.subtle
            font.pixelSize: Constants.fontBody
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
