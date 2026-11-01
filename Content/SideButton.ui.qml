import QtQuick
import QtQuick.Controls
import LobbyBalancer

// Small B / R toggle used to pick teams by hand. "selected" is driven from outside.
Button {
    id: root

    property bool selected: false
    property color accent: Constants.blueTeam

    implicitWidth: 30
    implicitHeight: 22
    padding: 0
    hoverEnabled: true
    font.pixelSize: Constants.fontCaption
    font.bold: true

    contentItem: Text {
        text: root.text
        font: root.font
        color: Constants.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: 5
        color: root.selected ? Constants.hover : (root.hovered ? Constants.raised : "transparent")
        border.width: 1
        border.color: root.visualFocus ? Constants.accent : (root.selected ? root.accent : Constants.lineStrong)

        Rectangle {
            visible: root.selected
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.bottomMargin: 2
            height: 3
            radius: 1.5
            color: root.accent
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
    }
}
