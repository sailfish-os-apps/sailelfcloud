import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"
import ".."

Page {
    id: page

    property int containerId
    property string containerName
    property string containerType: "top" // top, vault or cluster

    function _makeVisible() {
        busyIndication.running = false;
        contentListView.visible = true;
        noContentIndication.enabled = (contentListView.count === 0);
    }

    function _updateContentListAndShowPage(_parentId, contentList) {
        listModel.clear();
        for (var i = 0; i < contentList.length; i++) {
            console.debug("Adding:", contentList[i]["name"], "id:", contentList[i]["id"]);
            listModel.append({"item": contentList[i]});
        }
        _makeVisible();
    }

    function _updateForVaults() {
        elfCloud.listVaults();
    }

    function _updateForContainers() {
        elfCloud.listContent(containerId);
    }

    function _updateContent() {
        if (containerType === "top")
            _updateForVaults();
        else
            _updateForContainers();
    }

    function _actBusy() {
        busyIndication.running = true;
        contentListView.visible = false;
    }

    function _refresh() {
        _actBusy();
        _updateContent();
    }

    function _addVault() {
        var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/AddVaultDialog.qml"));
        dialog.onCreateVault.connect( function(name) {
            console.info("Creating vault", name);
            elfCloud.addVault(name);
        });
    }

    function _uploadCompleted(parentId, _remoteName, _localName, _dataItemsLeft) {
        if (containerId === parentId) { // if upload completed for our container
            _refresh();
        }
    }

    function _upload() {
        var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/FileChooserDialog.qml"))
        dialog.accepted.connect( function() {
            console.info("Uploading files: " + dialog.selectedPaths);
            elfCloud.storeDataItems(containerId, dialog.selectedPaths);
            });
    }

    BusyIndicator {
        id: busyIndication
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: true
    }

    function _createContentInfoString(modelItem) {
        if (modelItem["type"] === "dataitem")
            return qsTr("size: ") + modelItem["size"];
        else if (modelItem["type"] === "cluster")
            return "";
        else if (modelItem["type"] === "vault")
            return qsTr("owner: ") + modelItem["ownerFirstName"] + " " + modelItem["ownerLastName"];
    }

    function _openItem(modelItem) {
        if (modelItem["type"] === "cluster" ||
                modelItem["type"] === "vault") {
            pageStack.push(Qt.resolvedUrl("ContainerPage.qml"),
                           {"containerId":modelItem["id"],
                            "containerName":modelItem["name"],
                            "containerType":modelItem["type"]});
        } else if (modelItem["type"] === "dataitem") {
            pageStack.push(Qt.resolvedUrl("DataItemDetailsPage.qml"),
                           {"parentContainerId":containerId,
                            "dataItemName":modelItem["name"]});
        }
    }

    function _goBack() {
        pageStack.pop(null, PageStackAction.Animated);
    }

    function _handleClusterRemoved(id) {
        if (id === containerId)
            _goBack();
    }

    function _requestRemoveContainer() {
        if (containerType === "cluster")
            elfCloud.removeCluster(containerId);
    }

    function _removeContainer() {
        remorse.execute(qsTr("Removing") + " " + containerName, _requestRemoveContainer);
    }

    function _addCluster() {
        var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/AddClusterDialog.qml"));
        dialog.onCreateCluster.connect( function(name) {
                console.info("Creating cluster", name);
                elfCloud.addCluster(containerId, name);
            });
    }

    Component.onCompleted: {
        coverText = containerType !== "top" ? containerName : qsTr("Vaults")
        elfCloud.contentListed.connect(_updateContentListAndShowPage)
        elfCloud.storeDataItemCompleted.connect(_uploadCompleted);
        elfCloud.vaultAdded.connect(page._refresh);
        elfCloud.clusterAdded.connect(_refresh);
        elfCloud.clusterRemoved.connect(_handleClusterRemoved);
    }

    Component.onDestruction: {        
        elfCloud.contentListed.disconnect(_updateContentListAndShowPage)
        elfCloud.storeDataItemCompleted.disconnect(_uploadCompleted);
        elfCloud.vaultAdded.disconnect(page._refresh);
        elfCloud.clusterAdded.disconnect(_refresh);
        elfCloud.clusterRemoved.disconnect(_refresh);
    }

    onStatusChanged: {
        if (status === PageStatus.Activating)
            _refresh();
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
                visible: containerType === "top"
                onClicked: _addVault()
            }

            MenuItem {
                text: qsTr("Remove cluster")
                visible: containerType === "cluster"
                onClicked: _removeContainer()
            }

            MenuItem {
                text: qsTr("Add cluster")
                visible: containerType === "vault" || containerType === "cluster"
                onClicked: _addCluster()
            }

            MenuItem {
                text: qsTr("Upload file")
                visible: containerType === "vault" || containerType === "cluster"
                onClicked: _upload()
            }

            MenuItem {
                text: qsTr("Refresh")
                onClicked: _refresh();
            }

        }

        RemorsePopup { id: remorse }

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
                text: _createContentInfoString(model.item)
                font.pixelSize: Theme.fontSizeSmall
                color: itemContent.highlighted ? Theme.highlightColor : Theme.secondaryColor
            }

            onClicked: _openItem(model.item)
        }

        ViewPlaceholder {
            id: noContentIndication
            enabled: false
            text: "No content"
        }

        VerticalScrollDecorator {}
    }
}
