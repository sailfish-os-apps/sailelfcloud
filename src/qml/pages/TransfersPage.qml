import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"

Page {

    property var _listStoredAsyncCallRef: undefined
    property var _listFetchesAsyncCallRef: undefined

    signal _updateTransferList(var transfers)

    on_UpdateTransferList: {
        transferListModel.clear();

        for (var i = 0; i < transfers.length; i++) {
            console.log("populating", transfers[i].remoteName, transfers[i].type);
            transferListModel.append(transfers[i]);
        }

    }

    function _createModelDataFromTransfer(transfer, type) {
        return {
            "uid":transfer.uid,
            "remoteName":transfer.remoteName,
            "parentId":transfer.parentId,
            "totalSize":transfer.size,
            "completedSize":0,
            "state":transfer.state,
            "type":type
        };
    }

    function _listFetchesCb(fetches, transferList) {
        for (var i = 0; i < fetches.length; i++)
            transferList.push(_createModelDataFromTransfer(fetches[i], "fetch"));

        _updateTransferList(transferList);
    }

    function _listStoresCb(stores) {
        var transferList = [];
        for (var i = 0; i < stores.length; i++)
            transferList.push(_createModelDataFromTransfer(stores[i], "store"));

        // Note that we store async call reference so that we can invalidate it
        // if the elfCloud call is still in progress but this page is being closed.
        _listFetchesAsyncCallRef = elfCloud.listFetches(function(fetches) { _listFetchesCb(fetches, transferList); });
    }


    function _refresh() {
        // Note that we store async call reference so that we can invalidate it
        // if the elfCloud call is still in progress but this page is being closed.
        _listStoredAsyncCallRef = elfCloud.listStores(_listStoresCb);
    }

    function _storeStartedCb(parentId, remoteName, localName) {
        _refresh();
    }

    function _storeCompletedCb(parentId, remoteName, localName) {
        _refresh();
    }

    function _fetchStartedCb(parentId, remoteName, localName) {
        _refresh();
    }

    function _fetchCompletedCb(parentId, remoteName, localName) {
        _refresh();
    }

    function _update(parentId, remoteName, totalSize, transferredSize) {
        for (var i=0; i < transferListModel.count; i++) {
            var item = transferListModel.get(i);
            if (item.parentId === parentId && item.remoteName === remoteName) {
                transferListModel.setProperty(i, "totalSize", totalSize);
                transferListModel.setProperty(i, "completedSize", transferredSize);
            }
        }
    }

    function _storeChunkCompletedCb(parentId, remoteName, localName, totalSize, storedSize) {
        _update(parentId, remoteName, totalSize, storedSize);
    }

    function _fetchChunkCompletedCb(parentId, name, totalSize, fetchedSize) {
        _update(parentId, name, totalSize, fetchedSize);
    }

    Component.onCompleted: {
        elfCloud.storeDataItemStarted.connect(_storeStartedCb);
        elfCloud.storeDataItemChunkCompleted.connect(_storeChunkCompletedCb);
        elfCloud.storeDataItemCompleted.connect(_storeCompletedCb);

        elfCloud.fetchDataItemStarted.connect(_fetchStartedCb);
        elfCloud.fetchDataItemChunkCompleted.connect(_fetchChunkCompletedCb);
        elfCloud.fetchDataItemCompleted.connect(_fetchCompletedCb);

        _refresh();
    }

    Component.onDestruction: {
        elfCloud.storeDataItemStarted.disconnect(_storeStartedCb);
        elfCloud.storeDataItemChunkCompleted.disconnect(_storeChunkCompletedCb);
        elfCloud.storeDataItemCompleted.disconnect(_storeCompletedCb);

        elfCloud.fetchDataItemStarted.disconnect(_fetchStartedCb);
        elfCloud.fetchDataItemChunkCompleted.disconnect(_fetchChunkCompletedCb);
        elfCloud.fetchDataItemCompleted.disconnect(_fetchCompletedCb);

        if (_listStoredAsyncCallRef !== undefined)
            _listStoredAsyncCallRef.invalidate();

        if (_listFetchesAsyncCallRef !== undefined)
            _listFetchesAsyncCallRef.invalidate();
    }

    function _getIconForTransferState(state) {
        switch (state) {
        case "ongoing":
            return "image://theme/icon-m-transfer"
        case "todo":
            return "image://theme/icon-m-play"
        case "paused":
            return "image://theme/icon-m-pause"
        }

    }

    function _getIconForTransferType(type) {
        switch (type) {
        case "store":
            return "image://theme/icon-m-cloud-upload"
        case "fetch":
            return "image://theme/icon-m-cloud-download"
        }
    }

    function createTransferInfoStringForModelItem(modelItem) {
        return qsTr("Size:") + modelItem.totalSize;
    }

    function _pause(model) {
        if (model.type === "fetch")
            elfCloud.pauseDataItemFetch(model.uid);
        else
            elfCloud.pauseDataItemStore(model.uid);

        _refresh();
    }

    function _cancel(model) {
        if (model.type === "fetch")
            elfCloud.cancelDataItemFetch(model.uid);
        else
            elfCloud.cancelDataItemStore(model.uid);

        _refresh();
    }

    function _continue(model) {
        if (model.type === "fetch")
            elfCloud.resumeDataItemFetch(model.uid);
        else
            elfCloud.resumeDataItemStore(model.uid);

        _refresh();
    }


    SilicaListView {
        id: transfersListView
        model: ListModel { id: transferListModel }
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Transfers")
        }

        CommonPullDownMenu {
            id: pulldown
            transfersVisible: false

            MenuItem {
                text: qsTr("Refresh")
                onClicked: _refresh();
            }

        }

        section {
            property: 'type'
            delegate: SectionHeader {
                text: section === "fetch" ? qsTr("Downloads") : qsTr("Uploads")
            }
        }

        delegate: ListItem {
            id: itemContent
            width: parent.width
            contentHeight: remoteName.height + (model.state === "ongoing" ? transferProgress.height :
                                                                            todoTransferInfo.height)
            Image {
                id: transferModeIcon
                visible: model.state === "ongoing"
                x: Theme.paddingSmall
                y: Theme.paddingSmall
                source: _getIconForTransferType(model.type)
            }
            Image {
                id: transferStateIcon
                visible: model.state !== "ongoing"
                x: Theme.paddingSmall
                y: Theme.paddingSmall
                source: _getIconForTransferState(model.state)
            }
            Image {
                id: listIcon
                anchors.left: transferModeIcon.right
                x: Theme.paddingSmall
                y: Theme.paddingSmall
                source: "image://theme/icon-m-document"
            }

            Label {
                id: remoteName
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingSmall
                text: model.remoteName
                font.pixelSize: Theme.fontSizeSmall
                color: itemContent.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: todoTransferInfo
                visible: model.state !== "ongoing"
                anchors.top: remoteName.bottom
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingSmall
                text: createTransferInfoStringForModelItem(model)
                font.pixelSize: Theme.fontSizeSmall
                color: itemContent.highlighted ? Theme.highlightColor : Theme.secondaryColor
            }
            ProgressBar {
                id: transferProgress
                visible: model.state === "ongoing"
                anchors.top: remoteName.bottom
                anchors.left: listIcon.right
                width: parent.width - listIcon.width - transferModeIcon.width
                indeterminate: false
                maximumValue: 100.0
                value: (model.completedSize / model.totalSize) * 100
                valueText: progressValue.toFixed(0) + qsTr("%")
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Pause")
                        visible: model.state !== "paused"
                        onClicked: _pause(model)
                    }
                    MenuItem {
                        text: qsTr("Cancel")
                        onClicked: _cancel(model)
                    }
                    MenuItem {
                        text: qsTr("Continue")
                        visible: model.state === "paused"
                        onClicked: _continue(model)
                    }
                }
            }

        }

        ViewPlaceholder {
            id: noContentIndication
            enabled: transfersListView.count === 0
            text: qsTr("No transfers")
        }

        VerticalScrollDecorator {}
    }


}

