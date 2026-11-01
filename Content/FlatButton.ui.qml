import QtQuick
import QtQuick.Controls
import LobbyBalancer

// kind: "normal" | "primary" | "danger" | "ghost"
Button {
    id: root

    property string kind: "normal"

    readonly property bool isPrimary: kind === "primary"
    readonly property bool isDanger: kind === "danger"
    readonly property bool isGhost: kind === "ghost"

    readonly property color fillColor: isPrimary
                                       ? (down ? Constants.accentDown
                                               : (hovered ? Constants.accentHover : Constants.accent))
                                       : isDanger
                                         ? (hovered ? Constants.red : Constants.raised)
                                         : isGhost
                                           ? "transparent"
                                           : (down ? Constants.lineStrong : (hovered ? Constants.hover : Constants.raised))
    readonly property color edgeColor: isPrimary ? Constants.accent
                                       : isDanger ? Constants.red
                                       : isGhost ? (hovered ? Constants.red : "transparent")
                                       : Constants.lineStrong
    readonly property color inkColor: isPrimary ? Constants.accentInk
                                      : (isDanger && hovered) ? Constants.accentInk
                                      : (isGhost && !hovered) ? Constants.subtle
                                      : Constants.text

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: isGhost ? 26 : 34
    leftPadding: isGhost ? 8 : 14
    rightPadding: leftPadding
    topPadding: 0
    bottomPadding: 0
    hoverEnabled: true
    opacity: enabled ? 1 : 0.45
    font.pixelSize: isGhost ? Constants.fontSmall : Constants.fontBody
    font.bold: isPrimary

    contentItem: Text {
        text: root.text
        font: root.font
        color: root.inkColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: Constants.radiusControl
        color: root.fillColor
        border.width: 1
        border.color: root.visualFocus ? Constants.accent : root.edgeColor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
