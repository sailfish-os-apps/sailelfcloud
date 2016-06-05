import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property string oldName

    signal rename(var newName)

    Column {
        width: parent.width

        DialogHeader { title: qsTr("Rename") }

        TextField {
            id: nameField
            width: parent.width
            placeholderText: qsTr("New name")
            text: oldName
            label: "Name"
            EnterKey.onClicked: dialog.accept()
        }
    }

    onAccepted: rename(nameField.text)
    canAccept: nameField.text !== ""
}
