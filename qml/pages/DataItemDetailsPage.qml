import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    property int parentContainerId
    property string dataItemName

    function _viewDataItemContent() {
        elfCloud.fetchData(parentContainerId, dataItemName,
                           function(filename) {
                               pageStack.push(Qt.resolvedUrl("ViewPage.qml"),
                                              {"filename":filename,
                                               "cloudFilename":dataItemName});
                           });
    }

    function _removeDataItem() {
        elfCloud.removeFile(parentContainerId, dataItemName,
                            function() {
                                var prevPage = pageStack.previousPage();
                                pageStack.pop();
                                prevPage.refresh();
                            });
    }

    function _renameDataItem() {

    }

    function _makeVisible() {
        busyIndication.running = false;
        flickable.visible = true;
    }

    function _tagListToString(tagList) {
        return tagList.join(",");
    }

    function _updatePageContentWithItemInfo(itemInfo) {
        descriptionField.value = itemInfo["description"];
        tagsField.value = _tagListToString(itemInfo["tags"]);
        itemIdField.value = itemInfo["id"];
        sizeField.value = itemInfo["size"];
        accessedField.value = itemInfo["accessed"];
        md5Field.value = itemInfo["md5sum"];
        _makeVisible();
    }

    function _makeBusy() {
        busyIndication.running = true;
        flickable.visible = false;
    }

    function _updatePageContent() {
        _makeBusy();
        elfCloud.getDataItemInfo(parentContainerId, dataItemName, _updatePageContentWithItemInfo);
    }

    Component.onCompleted: {
        coverText = dataItemName;
        _updatePageContent();
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
                onClicked: { remorse.execute(qsTr("Deleting"),
                                             _removeDataItem); }
            }
            MenuItem {
                text: qsTr("Rename")
                onClicked: {}
            }

            MenuItem {
                text: qsTr("View Contents")
                onClicked:  { _viewDataItemContent(); }
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
                    id: md5Field
                    label: qsTr("MD5")
                }
            }            
        }
    }
}
