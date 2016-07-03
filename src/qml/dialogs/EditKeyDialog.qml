import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property string hash

    signal keyModified()

    function _modify(name, description) {
        keyHandler.modifyKey(hash, name, description);
        keyModified();
    }

    Component.onCompleted: {
        var key = keyHandler.getKey(hash);
        keyNameField.text = key["name"];
        keyDescriptionArea.text = key["description"];
        keyHashField.text = key["hash"];
    }

    Column {
        width: parent.width

        DialogHeader { title: qsTr("Edit key") }

        TextField {
            id:keyNameField
            width: parent.width
            label: qsTr("Name")
            labelVisible: true
            placeholderText: label
            EnterKey.onClicked: parent.focus = true
        }

        TextArea {
            id:keyDescriptionArea
            width: parent.width
            label: qsTr("Description")
            labelVisible: true
            placeholderText: label
            wrapMode: TextEdit.Wrap
        }

        TextField {
            id:keyHashField
            width: parent.width
            label: qsTr("Hash")
            labelVisible: true
            placeholderText: label
            readOnly: true
        }
    }

    onAccepted: _modify(keyNameField.text, keyDescriptionArea.text)
    canAccept: keyNameField.text !== ""
}
