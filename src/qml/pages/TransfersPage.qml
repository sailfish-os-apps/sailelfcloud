import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"

Page {

    property var _asyncCallRef1: undefined
    property var _asyncCallRef2: undefined

    function _listStoresCb(stores) {
        for (var i = 0; i < stores.length; i++) {
            if (stores[i]["state"] === "todo")
                transferListModel.append({"uid":stores[i].uid,
                                             "remoteName":stores[i].remoteName,
                                             "parentId":stores[i].parentId,
                                             "totalSize":stores[i].size,
                                             "completedSize":0,
                                             "section":qsTr("Uploads"),
                                             "state": "todo",
                                             "type":"store"});
            else if (stores[i]["state"] === "ongoing")
                transferListModel.append({"uid":stores[i].uid,
                                             "remoteName":stores[i].remoteName,
                                             "parentId":stores[i].parentId,
                                             "totalSize":stores[i].size,
                                             "completedSize":0,
                                             "section":qsTr("Ongoing"),
                                             "state": "ongoing",
                                             "type":"store"});
        }
    }

    function _listFetchesCb(fetches) {
        for (var i = 0; i < fetches.length; i++) {
            if (fetches[i]["state"] === "todo")
                transferListModel.append({"uid":stores[i].uid,
                                             "remoteName":stores[i].remoteName,
                                             "parentId":stores[i].parentId,
                                             "totalSize":0,
                                             "completedSize":0,
                                             "section":qsTr("Uploads"),
                                             "state": "todo",
                                             "type":"fetch"});
            else if (fetches[i]["state"] === "ongoing")
                transferListModel.append({"uid":stores[i].uid,
                                             "remoteName":stores[i].remoteName,
                                             "parentId":stores[i].parentId,
                                             "totalSize":0,
                                             "completedSize":0,
                                             "section":qsTr("Ongoing"),
                                             "state": "ongoing",
                                             "type":"fetch"});
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

    function _update(parentId, remoteName, totalSize, storedSize) {
        for (var i=0; i < transferListModel.count; i++) {
            var item = transferListModel.get(i);
            if (item.parentId === parentId && item.remoteName === remoteName) {
                transferListModel.setProperty(i, "completedSize", storedSize);
            }
        }
    }

    function _chunkCompletedCb(parentId, remoteName, localName, totalSize, storedSize) {
        _update(parentId, remoteName, totalSize, storedSize);
    }


    Component.onCompleted: {
        elfCloud.storeDataItemCompleted.connect(_storeCompletedCb);
        elfCloud.storeDataItemChunkCompleted.connect(_chunkCompletedCb);
        _refresh();
    }

    Component.onDestruction: {
        elfCloud.storeDataItemCompleted.disconnect(_storeCompletedCb);
        elfCloud.storeDataItemChunkCompleted.disconnect(_chunkCompletedCb);

        if (_asyncCallRef !== undefined)
            _asyncCallRef.invalidate();
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
        return qsTr("Size:") + modelItem.size;
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

        delegate: BackgroundItem {
            id: itemContent
            width: parent.width
            height: remoteName.height + (model.state === "ongoing" ? transferProgress.height :
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
                visible: model.state === "todo"
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
                value: (model.completedSize / model.size) * 100
                valueText: progressValue.toFixed(0) + qsTr("%")
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

