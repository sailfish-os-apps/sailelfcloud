import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"
import ".."

Page {
    id: page

    property var containerId
    property var containerName

    function makeVisible() {
        busyIndication.running = false;
        contentListView.visible = true;
        noContentIndication.enabled = (contentListView.count === 0);
    }

    function updateContent() {
        elfCloud.listContent(containerId, function(contentList) {
            listModel.clear();
            for (var i = 0; i < contentList.length; i++) {
                console.log("Item:", contentList[i]["name"], "id:", contentList[i]["id"]);
                listModel.append({"item": contentList[i]});
            }
            page.makeVisible();
         });
    }

    function actBusy() {
        busyIndication.running = true;
        contentListView.visible = false;
    }

    function refresh() {
        actBusy();
        updateContent();
    }

    onStatusChanged: {
        if (status === PageStatus.Activating)
            refresh();
    }

    function uploadCompleted(parentId) {
        if (containerId === parentId) // if upload completed for our container
            refresh();
    }

    Component.onCompleted: {
        coverText = containerName
        elfCloud.uploadCompleted.connect(page.uploadCompleted);
    }

    Component.onDestruction: {
        elfCloud.uploadCompleted.disconnect(page.uploadCompleted);
    }

    BusyIndicator {
        id: busyIndication
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: true
    }

    SilicaListView {
        id: contentListView
        visible: false
        model: ListModel { id: listModel }
        anchors.fill: parent        

        header: PageHeader {
            title: containerName
        }

        CommonPullDownMenu {
            id: pulldown

            MenuItem {
                text: qsTr("Add cluster")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/AddClusterDialog.qml"));
                    dialog.onCreateCluster.connect( function(name) {
                        console.info("Creating cluster", name);
                        elfCloud.addCluster(containerId, name, function() { page.refresh(); });
                    });
                }
            }

            MenuItem {
                text: qsTr("Upload file")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/FileChooserDialog.qml"))
                    dialog.accepted.connect( function() {
                        console.info("Uploading files: " + dialog.selectedPaths);
                        elfCloud.uploadFiles(containerId, dialog.selectedPaths);
                        });
                }
            }

            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    page.refresh();
                }
            }

        }

        delegate: BackgroundItem {
            id: itemContent
            width: parent.width

            Image {
                id: listIcon
                x: Theme.paddingLarge
                y: Theme.paddingMedium
                source: model.item["type"] === "cluster" ? "image://theme/icon-m-folder" : "image://theme/icon-m-document"
            }
            Label {
                id: labelContentName
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                text: model.item["name"]
                color: itemContent.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: contentInfo
                anchors.top: labelContentName.bottom
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                text: qsTr("size: ") + model.item["size"]
                font.pixelSize: Theme.fontSizeSmall
                color: itemContent.highlighted ? Theme.highlightColor : Theme.secondaryColor
            }

            onClicked: {
                if (model.item["type"] === "cluster") {
                    pageStack.push(Qt.resolvedUrl("ContentPage.qml"),
                                   {"containerId":model.item["id"],
                                    "containerName":model.item["name"]});
                } else if (model.item["type"] === "dataitem") {
                    pageStack.push(Qt.resolvedUrl("DataItemDetailsPage.qml"),
                                   {"parentContainerId":containerId,
                                    "dataItemName":model.item["name"]});
                }
            }
        }

        ViewPlaceholder {
            id: noContentIndication
            enabled: false
            text: "No content"
        }

        VerticalScrollDecorator {}
    }
}
