import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"
import ".."

Page {
    id: page

    property var containerId: null // This is null if vaults should be shown
    property var containerName: null

    function makeVisible() {
        busyIndication.running = false;
        contentListView.visible = true;
        noContentIndication.enabled = (contentListView.count === 0);
    }

    function updateContentListAndShowPage(contentList) {
        listModel.clear();
        for (var i = 0; i < contentList.length; i++) {
            console.debug("Adding:", contentList[i]["name"], "id:", contentList[i]["id"]);
            listModel.append({"item": contentList[i]});
        }
        makeVisible();
    }

    function updateForVaults() {
        elfCloud.listVaults(updateContentListAndShowPage);
    }

    function updateForContainers() {
        elfCloud.listContent(containerId, updateContentListAndShowPage);
    }

    function updateContent() {
        if (containerId === null)
            updateForVaults();
        else
            updateForContainers();
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
        coverText = containerName !== null ? containerName : qsTr("Vaults")
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

    function createContentInfoString(modelItem) {
        if (modelItem["type"] === "dataitem")
            return qsTr("size: ") + modelItem["size"];
        else if (modelItem["type"] === "cluster")
            return "";
        else if (modelItem["type"] === "vault")
            return qsTr("owner: ") + modelItem["ownerFirstName"] + " " + modelItem["ownerLastName"];
    }

    function openItem(modelItem) {
        if (modelItem["type"] === "cluster" ||
                modelItem["type"] === "vault") {
            pageStack.push(Qt.resolvedUrl("ContainerPage.qml"),
                           {"containerId":modelItem["id"],
                            "containerName":modelItem["name"]});
        } else if (modelItem["type"] === "dataitem") {
            pageStack.push(Qt.resolvedUrl("DataItemDetailsPage.qml"),
                           {"parentContainerId":containerId,
                            "dataItemName":modelItem["name"]});
        }
    }

    SilicaListView {
        id: contentListView
        visible: false
        model: ListModel { id: listModel }
        anchors.fill: parent        

        header: PageHeader {
            title: containerName !== null ? containerName : qsTr("Vaults")
        }

        CommonPullDownMenu {
            id: pulldown

            MenuItem {
                text: qsTr("Add vault")
                visible: containerId === null
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/AddVaultDialog.qml"));
                    dialog.onCreateVault.connect( function(name) {
                        console.info("Creating vault", name);
                        elfCloud.addVault(name, page.refresh);
                    });
                }
            }

            MenuItem {
                text: qsTr("Add cluster")
                visible: containerId !== null
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/AddClusterDialog.qml"));
                    dialog.onCreateCluster.connect( function(name) {
                        console.info("Creating cluster", name);
                        elfCloud.addCluster(containerId, name, page.refresh);
                    });
                }
            }

            MenuItem {
                text: qsTr("Upload file")
                visible: containerId !== null
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
                source: model.item["type"] === "dataitem" ? "image://theme/icon-m-document" : "image://theme/icon-m-folder"
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
                text: createContentInfoString(model.item)
                font.pixelSize: Theme.fontSizeSmall
                color: itemContent.highlighted ? Theme.highlightColor : Theme.secondaryColor
            }

            onClicked: openItem(model.item)
        }

        ViewPlaceholder {
            id: noContentIndication
            enabled: false
            text: "No content"
        }

        VerticalScrollDecorator {}
    }
}
