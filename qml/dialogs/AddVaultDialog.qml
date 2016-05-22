import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    signal createVault(var name)

    Column {
        width: parent.width

        DialogHeader { }

        TextField {
            id: nameField
            width: parent.width
            placeholderText: qsTr("Vault name")
            label: "Name"
            EnterKey.onClicked: dialog.accept()
        }
    }

    onAccepted: createVault(nameField.text)
    canAccept: nameField.text !== ""
}
