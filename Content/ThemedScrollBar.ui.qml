import QtQuick
import QtQuick.Controls
import LobbyBalancer

ScrollBar {
    id: root

    policy: ScrollBar.AsNeeded
    implicitWidth: 8

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 40
        radius: 3
        color: root.pressed ? Constants.muted : Constants.lineStrong
        opacity: root.size < 1.0 ? 1 : 0
    }
}
