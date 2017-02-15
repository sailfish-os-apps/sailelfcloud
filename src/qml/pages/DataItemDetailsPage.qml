import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    property int parentContainerId
    property string dataItemName
    property var _asycCallRef: undefined
    property bool _canView: false // true if item is encrypted and key for it exist, otherwise false
    property var _key: undefined
    property var _iv: undefined

    function _downloadDataItem() {
        var outputPath = helpers.generateLocalPathForRemoteDataItem(parentContainerId, dataItemName);
        console.debug("Downloading", dataItemName, "from", parentContainerId, "to", outputPath);

        if (_key !== undefined && _iv !== undefined)
            elfCloud.setEncryptionKey(_key, _iv);
        else
            elfCloud.clearEncryption();

        _asycCallRef = elfCloud.fetchAndMoveDataItem(parentContainerId, dataItemName, outputPath, false);
    }

    function _viewDataItemContent() {
        pageStack.push(Qt.resolvedUrl("DataItemContentPage.qml"),
                       {"dataItemName":dataItemName,
                        "parentContainerId":parentContainerId,
                        "key":_key,
                        "iv":_iv});
    }

    function _goBackAfterRemoveRemoved() {
        pageStack.pop();
    }

    function _requestRemoveDataItem() {
        _asycCallRef = elfCloud.removeDataItem(parentContainerId, dataItemName,
                                               _goBackAfterRemoveRemoved);
    }

    function _removeDataItem() {
        remorse.execute(qsTr("Deleting"), _requestRemoveDataItem);
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

    function _updatePageContentWithItemInfo(itemInfo) {
        descriptionField.value = itemInfo["description"];
        tagsField.value = _tagListToString(itemInfo["tags"]);
        itemIdField.value = itemInfo["id"];
        sizeField.value = itemInfo["size"];
        accessedField.value = itemInfo["accessed"];
        hashField.value = itemInfo["contentHash"];
        keyHashField.value = itemInfo["keyHash"];
        _canView = itemInfo['encryption'] === "NONE" ||
                (itemInfo['encryption'] !== "NONE" && keyHandler.isKey(itemInfo["keyHash"]))

        var key = keyHandler.getKey(itemInfo["keyHash"])
        if (key) {
            _key = key['key'];
            _iv = key['iv'];
            keyNameField.value = key['name']
        } else if (!key && itemInfo['encryption'] !== "NONE") {
            keyNameField.value = qsTr("No decryption key available")
        }

        _makeVisible();
    }

    function _refresh() {
        _makeBusy();
        _asycCallRef = elfCloud.getDataItemInfo(parentContainerId, dataItemName,
                                                _updatePageContentWithItemInfo);
    }

    function _refreshAfterRename(newName) {
        dataItemName = newName;
        _refresh();
    }

    function _renameDataItem() {
        var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/RenameDialog.qml"), {"oldName":dataItemName});
        dialog.onRename.connect( function(newName) {
            _asycCallRef = elfCloud.renameDataItem(parentContainerId, dataItemName,
                                                   newName, function() {_refreshAfterRename(newName);});
        });
    }

    Component.onCompleted: {
        _refresh();
    }

    Component.onDestruction: {
        if (_asycCallRef !== undefined)
            _asycCallRef.invalidate();
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
                enabled: _canView
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
                    enabled: _canView
                    width: parent.width
                    height: openArea.height
                    onClicked: {
                        openButton.enabled = false; // prevent multiple clicks
                        if (_canView)
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
                        Item {
                            width: parent.width
                            height: Theme.paddingLarge
                        }
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
                DetailItem {
                    id: keyNameField
                    label: qsTr("Decryption key")
                }

            }
        }
    }
}
