import QtQuick 2.0
import Sailfish.Silica 1.0

Page
{
    id: page
    property string hash

    Component.onCompleted: {
        var key = keyHandler.getKey(hash);
        nameItem.value = key["name"];
        descriptionItem.value = key["description"];
        dataItem.value = key["key"];
        ivItem.value = key["iv"];
        hashItem.value = key["hash"];
        modeItem.value = key["mode"];
        typeItem.value = key["type"];
        fileItem.value = helpers.getFilenameFromPath(key["file"]);
    }

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

    }
}
