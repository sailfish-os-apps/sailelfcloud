import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    property var parentContainerId
    property var dataItemId
    property var dataItemName

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

    Component.onCompleted: {
        coverText = dataItemName
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            openButton.enabled = true; // may be disabled if button is pressed
        }
    }

    SilicaFlickable {
        id: flickable
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
                    label: qsTr("Id")
                    value: dataItemId
                }

                DetailItem {
                    label: qsTr("ParentId")
                    value: parentContainerId
                }
            }            
        }
    }
}
