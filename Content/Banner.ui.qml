import QtQuick
import LobbyBalancer

// A message strip with a colored edge: yellow = warning, red = error, aqua = notice.
Rectangle {
    id: root

    property alias text: label.text
    property color accent: Constants.yellow

    implicitWidth: 400
    implicitHeight: label.implicitHeight + 20
    color: Constants.raised
    radius: 6

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        radius: 2
        color: root.accent
    }

    Text {
        id: label
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        color: Constants.text
        font.pixelSize: Constants.fontBody
        wrapMode: Text.WordWrap
        text: "Message"
    }
}
