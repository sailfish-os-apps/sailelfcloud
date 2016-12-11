import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"

Page {

    property var _asyncCallRef1: undefined
    property var _asyncCallRef2: undefined

    function _listStoresCb(stores) {
        for (var i = 0; i < stores.length; i++) {
            if (stores[i]["state"] === "todo")
                transferListModel.append({
                                             "uid":stores[i].uid,
                                             "remoteName":stores[i].remoteName,
                                             "parentId":stores[i].parentId,
                                             "totalSize":stores[i].size,
                                             "completedSize":0,
                                             "section":qsTr("Uploads"),
                                             "state": "todo",
                                             "type":"store"
                                         });
            else if (stores[i]["state"] === "ongoing")
                transferListModel.append({
                                             "uid":stores[i].uid,
                                             "remoteName":stores[i].remoteName,
                                             "parentId":stores[i].parentId,
                                             "totalSize":stores[i].size,
                                             "completedSize":0,
                                             "section":qsTr("Ongoing"),
                                             "state": "ongoing",
                                             "type":"store"
                                         });
        }
    }

    function _listFetchesCb(fetches) {
        console.log("listFetches", fetches)
        for (var i = 0; i < fetches.length; i++) {
            if (fetches[i]["state"] === "todo")
                transferListModel.append({
                                             "uid":fetches[i].uid,
                                             "remoteName":fetches[i].remoteName,
                                             "parentId":fetches[i].parentId,
                                             "totalSize":fetches[i].size,
                                             "completedSize":0,
                                             "section":qsTr("Downloads"),
                                             "state": "todo",
                                             "type":"fetch"
                                         });
            else if (fetches[i]["state"] === "ongoing")
                transferListModel.append({
                                             "uid":fetches[i].uid,
                                             "remoteName":fetches[i].remoteName,
                                             "parentId":fetches[i].parentId,
                                             "totalSize":fetches[i].size,
                                             "completedSize":0,
                                             "section":qsTr("Ongoing"),
                                             "state": "ongoing",
                                             "type":"fetch"
                                         });
            else if (fetches[i]["state"] === "paused")
                transferListModel.append({
                                             "uid":fetches[i].uid,
                                             "remoteName":fetches[i].remoteName,
                                             "parentId":fetches[i].parentId,
                                             "totalSize":fetches[i].size,
                                             "completedSize":0,
                                             "section":qsTr("Downloads"),
                                             "state": "paused",
                                             "type":"fetch"
                                         });
        }
    }

    function _refresh() {
        transferListModel.clear();
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

    function _fetchChunkCompletedCb(parentId, name, totalSize, fetchedSize) {
        _update(parentId, name, totalSize, fetchedSize);
    }

    function _fetchCompletedCb(parentId, remoteName, localName) {
        _refresh();
    }


    Component.onCompleted: {
        elfCloud.storeDataItemCompleted.connect(_storeCompletedCb);
        elfCloud.storeDataItemChunkCompleted.connect(_storeChunkCompletedCb);
        elfCloud.fetchDataItemChunkCompleted.connect(_fetchChunkCompletedCb);
        elfCloud.fetchDataItemCompleted.connect(_fetchCompletedCb);

        _refresh();
    }

    Component.onDestruction: {
        elfCloud.storeDataItemCompleted.disconnect(_storeCompletedCb);
        elfCloud.storeDataItemChunkCompleted.disconnect(_storeChunkCompletedCb);
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

    SilicaListView {
        id: transfersListView
        model: ListModel { id: transferListModel }
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Transfers")
        }

        CommonPullDownMenu {
            id: pulldown

            MenuItem {
                text: qsTr("Refresh")
                onClicked: _refresh();
            }

        }

        section {
            property: 'section'
            delegate: SectionHeader {
                text: section
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
                        visible: model.state === "ongoing"
                        onClicked: elfCloud.pauseDataItemFetch(model.uid)
                    }
                    MenuItem {
                        text: qsTr("Cancel")
                        onClicked: elfCloud.cancelDataItemFetch(model.uid)
                    }
                    MenuItem {
                        text: qsTr("Continue")
                        visible: model.state === "paused"
                        onClicked: console.log("continue")
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

