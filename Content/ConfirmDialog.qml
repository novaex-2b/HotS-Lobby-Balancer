import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LobbyBalancer

// A themed confirmation dialog. Runtime-only, so it is a plain .qml file.
Dialog {
    id: root

    property string message: ""
    property string confirmText: qsTr("Yes")
    signal confirmed

    modal: true
    anchors.centerIn: Overlay.overlay
    width: 420
    padding: 20
    closePolicy: Popup.CloseOnEscape

    // The title is drawn inside the content below, so remove the style's own header bar.
    header: Item {}

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.5)
    }

    background: Rectangle {
        color: Constants.surface
        radius: Constants.radiusCard
        border.color: Constants.lineStrong
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Constants.text
            font.pixelSize: Constants.fontBody + 2
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            text: root.message
            color: Constants.text
            font.pixelSize: Constants.fontBody
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            FlatButton {
                objectName: "dialogCancel"
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            FlatButton {
                objectName: "dialogConfirm"
                kind: "danger"
                text: root.confirmText
                onClicked: {
                    root.close()
                    root.confirmed()
                }
            }
        }
    }
}
