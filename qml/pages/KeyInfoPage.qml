import QtQuick 2.0
import Sailfish.Silica 1.0

Page
{
    id: page
    property string hash
    property var _key

    signal keyDeleted(string hash)

    Component.onCompleted: {
        _key = keyHandler.getKey(hash);
        nameItem.value = _key["name"];
        descriptionItem.value = _key["description"];
        dataItem.value = _key["key"];
        ivItem.value = _key["iv"];
        hashItem.value = _key["hash"];
        modeItem.value = _key["mode"];
        typeItem.value = _key["type"];
        fileItem.value = helpers.getFilenameFromPath(_key["file"]);
    }

    function _deleteKey() {
        keyHandler.removeKey(_key["hash"]);
        keyDeleted(hash);
        pageStack.pop();
    }

    function _proceedKeyDeletion() {
        remorse.execute(qsTr("Removing key") + " " + _key["name"], _deleteKey);
    }

    function _requestKeyDelete() {
        var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/DeleteKeyConfirmationDialog.qml"),
                                    {"name": _key["name"],
                                     "hash": _key["hash"]});
        dialog.accepted.connect(_proceedKeyDeletion);
    }


    SilicaFlickable {
            anchors.fill: parent
            contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Delete key")
                onClicked: _requestKeyDelete()
            }
        }

        RemorsePopup { id: remorse }

        Column
        {
            id: column

            spacing: Theme.paddingMedium
            width: parent.width

            PageHeader { title: qsTr("Key information") }

            DetailItem {
                id: nameItem
                label: qsTr("Name")
            }
            DetailItem {
                id: descriptionItem
                label: qsTr("Description")
            }
            DetailItem {
                id: dataItem
                label: qsTr("Key data")
            }
            DetailItem {
                id: ivItem
                label: qsTr("Initialization vector")
            }
            DetailItem {
                id: hashItem
                label: qsTr("Hash")
            }
            DetailItem {
                id: modeItem
                label: qsTr("Mode")
            }
            DetailItem {
                id: typeItem
                label: qsTr("Type")
            }
            DetailItem {
                id: fileItem
                label: qsTr("Filename")
            }

            VerticalScrollDecorator {}
        }
    }
}
