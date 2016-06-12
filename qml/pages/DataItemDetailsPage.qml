import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    property int parentContainerId
    property string dataItemName

    function _downloadDataItem() {
        var outputPath = helpers.generateLocalPathForRemoteDataItem(parentContainerId, dataItemName);
        console.debug("Downloading", dataItemName, "from", parentContainerId, "to", outputPath);
        elfCloud.fetchAndMoveDataItem(parentContainerId, dataItemName, outputPath, false);
    }

    function _viewDataItemContent() {
        pageStack.push(Qt.resolvedUrl("DataItemContentPage.qml"),
                       {"dataItemName":dataItemName,
                        "parentContainerId":parentContainerId});
    }

    function _goBack() {
        pageStack.pop();
    }

    function _requestRemoveDataItem() {
        elfCloud.removeDataItem(parentContainerId, dataItemName);
    }

    function _removeDataItem() {
        remorse.execute(qsTr("Deleting"), _requestRemoveDataItem);
    }

    function _refreshAfterRename(_parentId, _oldName, newName) {
        dataItemName = newName;
        _refresh();
    }

    function _renameDataItem() {
        var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/RenameDialog.qml"), {"oldName":dataItemName});
        dialog.onRename.connect( function(newName) {
            elfCloud.renameDataItem(parentContainerId, dataItemName, newName);
        });
    }

    function _makeVisible() {
        busyIndication.running = false;
        flickable.visible = true;
    }

    function _tagListToString(tagList) {
        return tagList.join(",");
    }

    function _makeBusy() {
        busyIndication.running = true;
        flickable.visible = false;
    }

    function _refresh() {
        _makeBusy();
        elfCloud.getDataItemInfo(parentContainerId, dataItemName);
    }

    function _updatePageContentWithItemInfo(_parentId, _name, itemInfo) {
        descriptionField.value = itemInfo["description"];
        tagsField.value = _tagListToString(itemInfo["tags"]);
        itemIdField.value = itemInfo["id"];
        sizeField.value = itemInfo["size"];
        accessedField.value = itemInfo["accessed"];
        hashField.value = itemInfo["contentHash"];
        keyHashField.value = itemInfo["keyHash"];
        _makeVisible();
    }

    Component.onCompleted: {
        elfCloud.dataItemInfoGot.connect(_updatePageContentWithItemInfo)
        elfCloud.dataItemRenamed.connect(_refreshAfterRename);
        elfCloud.dataItemRemoved.connect(_goBack);
        coverText = dataItemName;
        _refresh();
    }

    Component.onDestruction: {
        elfCloud.dataItemInfoGot.disconnect(_updatePageContentWithItemInfo)
        elfCloud.dataItemRenamed.disconnect(_refreshAfterRename);
        elfCloud.dataItemRemoved.disconnect(_goBack);
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            openButton.enabled = true; // may be disabled if button is pressed
        }
    }

    BusyIndicator {
        id: busyIndication
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: true
    }

    SilicaFlickable {
        id: flickable
        visible: false
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        PullDownMenu {
            MenuItem {
                text: qsTr("Delete")
                onClicked: _removeDataItem()
            }
            MenuItem {
                text: qsTr("Rename")
                onClicked: _renameDataItem()
            }

            MenuItem {
                text: qsTr("Download")
                onClicked: _downloadDataItem()
            }

            MenuItem {
                text: qsTr("View Contents")
                onClicked: _viewDataItemContent()
            }
        }

        RemorsePopup { id: remorse }


        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                title: dataItemName
            }

            // file info texts, visible if error is not set
            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x


                BackgroundItem {
                    id: openButton
                    width: parent.width
                    height: openArea.height
                    onClicked: {
                        openButton.enabled = false; // prevent multiple clicks
                        _viewDataItemContent(parentContainerId, dataItemName);
                    }

                    Column {
                        id: openArea
                        width: parent.width

                        Image {
                            id: icon
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: "image://theme/icon-l-document"
                        }
                        Label {
                            id: filename
                            width: parent.width
                            text: dataItemName
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            color: openButton.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Spacer { height: Theme.paddingLarge }
                    }
                }
                DetailItem {
                    id: descriptionField
                    label: qsTr("Description")
                }              
                DetailItem {
                    id: tagsField
                    label: qsTr("Tags")
                }
                DetailItem {
                    id: itemIdField
                    label: qsTr("Id")
                }
                DetailItem {
                    label: qsTr("ParentId")
                    value: parentContainerId
                }
                DetailItem {
                    id: sizeField
                    label: qsTr("Size")
                }
                DetailItem {
                    id: accessedField
                    label: qsTr("Last access time")
                }
                DetailItem {
                    id: hashField
                    label: qsTr("Hash")
                }
                DetailItem {
                    id: keyHashField
                    label: qsTr("Key hash")
                }
            }
        }
    }
}
