import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"
import ".."

Page {
    id: page

    property string parentName
    property ContentDetailsType details

    signal refresh()

    Component.onCompleted: {
        refresh();
        elfCloud.uploadCompleted.connect(page.uploadCompleted);
    }

    Component.onDestruction: {
        elfCloud.uploadCompleted.disconnect(page.uploadCompleted);
    }

    onRefresh: {
        actBusy();
        listModel.clear();
        updateContent();
    }

    function updateContent() {
        coverText = details.contentName // coverText can be found from SailElfCloud.qml as property
        elfCloud.listContent(details.contentId, function(contentList) {
            for (var i = 0; i < contentList.length; i++) {
                console.log("Cluster: " + contentList[i].contentName + " id: " + contentList[i].contentId);
                listModel.append({"dataItem": contentList[i]});
            }
            page.makeVisible();
         });
    }

    function actBusy() {
        busyIndication.running = true;
        contentListView.visible = false;
    }

    function makeVisible() {
        busyIndication.running = false;
        contentListView.visible = true;
        noContentIndication.enabled = (contentListView.count === 0);
    }

    function uploadCompleted(parentId) {
        if (details.contentId === parentId)
            refresh();
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
            title: details.contentName
        }

        CommonPullDownMenu {
            id: pulldown

            MenuItem {
                text: qsTr("Add cluster")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/AddClusterDialog.qml"));
                    dialog.onCreateCluster.connect( function(name) {
                        console.info("Creating cluster", name);
                        elfCloud.addCluster(details.contentId, name, function() { page.refresh(); });
                    });
                }
            }

            MenuItem {
                text: qsTr("Upload file")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/FileChooserDialog.qml"))
                    dialog.accepted.connect( function() {
                        console.info("Uploading files: " + dialog.selectedPaths);
                        elfCloud.uploadFiles(details.contentId, dialog.selectedPaths);
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
                source: model.dataItem.contentType === "cluster" ? "image://theme/icon-m-folder" : "image://theme/icon-m-document"
            }
            Label {
                id: labelContentName
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                text: model.dataItem.contentName
                color: itemContent.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: contentInfo
                anchors.top: labelContentName.bottom
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                text: qsTr("size: ") + model.dataItem.contentSize
                font.pixelSize: Theme.fontSizeSmall
                color: itemContent.highlighted ? Theme.highlightColor : Theme.secondaryColor
            }

            onClicked: {
                if (model.dataItem.contentType === "cluster") {
                    pageStack.push(Qt.resolvedUrl("ContentPage.qml"),
                                   {"details":model.dataItem});
                } else if (model.dataItem.contentType === "dataitem") {
                    pageStack.push(Qt.resolvedUrl("DataItemDetailsPage.qml"),
                                   {"details":model.dataItem});
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
