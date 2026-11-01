import QtQuick
import QtQuick.Layouts
import LobbyBalancer

// A titled panel. Anything placed inside a Card goes into its body.
Rectangle {
    id: root

    property string title: "Title"
    property string rightText: ""
    default property alias content: body.data

    implicitWidth: 400
    implicitHeight: layout.implicitHeight + 28
    color: Constants.surface
    radius: Constants.radiusCard
    border.color: Constants.line
    border.width: 1

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.title
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
                text: root.rightText
                color: Constants.subtle
                font.pixelSize: Constants.fontSmall
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 10
        }
    }
}
