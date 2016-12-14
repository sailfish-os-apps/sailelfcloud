import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"

Page {

    property var _asyncCallRef1: undefined
    property var _asyncCallRef2: undefined

    signal _updateTransferList(var transfers)

    on_UpdateTransferList: {
        transferListModel.clear();

        for (var i = 0; i < transfers.length; i++) {
            console.log("populating", transfers[i]);
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

    function _listStoresCb(stores) {
        var transferList = [];
        for (var i = 0; i < stores.length; i++)
            transferList.push(_createModelDataFromTransfer(stores[i], "store"));

        _updateTransferList(transferList);
    }

    function _listFetchesCb(fetches) {
        var transferList = [];
        for (var i = 0; i < fetches.length; i++)
            transferList.push(_createModelDataFromTransfer(fetches[i], "fetch"));

        _updateTransferList(transferList);
    }

    function _refresh() {
        // Note that we store async call reference so that we can invalidate it
        // if the elfCloud call is still in progress but this page is being closed.
        _asyncCallRef1 = elfCloud.listStores(_listStoresCb);
        _asyncCallRef2 = elfCloud.listFetches(_listFetchesCb);
    }

    function _storeCompletedCb(parentId, remoteName, localName, dataItemsLeft) {
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

    function _fetchStartedCb(parentId, remoteName, localName) {
        _refresh();
    }

    function _fetchChunkCompletedCb(parentId, name, totalSize, fetchedSize) {
        _update(parentId, name, totalSize, fetchedSize);
    }

    function _fetchCompletedCb(parentId, remoteName, localName) {
        _refresh();
    }


    Component.onCompleted: {
        elfCloud.storeDataItemCompleted.connect(_storeCompletedCb);
        elfCloud.storeDataItemChunkCompleted.connect(_storeChunkCompletedCb);

        elfCloud.fetchDataItemStarted.connect(_fetchStartedCb);
        elfCloud.fetchDataItemChunkCompleted.connect(_fetchChunkCompletedCb);
        elfCloud.fetchDataItemCompleted.connect(_fetchCompletedCb);

        _refresh();
    }

    Component.onDestruction: {
        elfCloud.storeDataItemCompleted.disconnect(_storeCompletedCb);
        elfCloud.storeDataItemChunkCompleted.disconnect(_storeChunkCompletedCb);

        elfCloud.fetchDataItemStarted.disconnect(_fetchStartedCb);
        elfCloud.fetchDataItemChunkCompleted.disconnect(_fetchChunkCompletedCb);
        elfCloud.fetchDataItemCompleted.disconnect(_fetchCompletedCb);

        if (_asyncCallRef1 !== undefined)
            _asyncCallRef1.invalidate();

        if (_asyncCallRef2 !== undefined)
            _asyncCallRef2.invalidate();
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

        _refresh();
    }

    function _cancel(model) {
        if (model.type === "fetch")
            elfCloud.cancelDataItemFetch(model.uid);

        _refresh();
    }

    function _continue(model) {
        if (model.type === "fetch")
            elfCloud.resumeDataItemFetch(model.uid);

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
                text: type === "store" ? qsTr("Uploads") : qsTr("Downloads")
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

