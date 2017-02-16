import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

CoverBackground {

    property int _uploadsTodo: 0
    property int _downloadsTodo: 0

    property var _listStoredAsyncCallRef: undefined
    property var _listFetchesAsyncCallRef: undefined

    signal _setUploadsTodo(int count)
    signal _setDownloadsTodo(int count)

    on_SetDownloadsTodo: { if (_downloadsTodo != count) _downloadsTodo = count; }
    on_SetUploadsTodo: { if (_uploadsTodo != count) _uploadsTodo = count; }

    signal _updateUploadsTodo(int change)
    signal _updateDownloadsTodo(int change)

    on_UpdateDownloadsTodo: { _downloadsTodo += change; }
    on_UpdateUploadsTodo: { _uploadsTodo += change; }

    on_UploadsTodoChanged: {
        uploadingLabel.text = _uploadsTodo;
        uploadingLabel.visible = (_uploadsTodo > 0);
    }
    on_DownloadsTodoChanged: {
        downloadingLabel.text = _downloadsTodo;
        downloadingLabel.visible = (_downloadsTodo > 0);
    }

    function _listFetchesCb(fetches) {
        _setDownloadsTodo(fetches.length);
    }

    function _listStoresCb(stores) {
        _setUploadsTodo(stores.length);
    }

    function _transferStartedCb() {
        _listFetchesAsyncCallRef = elfCloud.listFetches(_listFetchesCb);
        _listStoredAsyncCallRef = elfCloud.listStores(_listStoresCb);
    }

    function _storeCompletedCb() {
        _updateUploadsTodo(-1);
    }

    function _fetchCompletedCb() {
        _updateDownloadsTodo(-1);
    }

    Component.onCompleted: {
        elfCloud.storeDataItemStarted.connect(_transferStartedCb);
        elfCloud.storeDataItemCompleted.connect(_storeCompletedCb);
        elfCloud.storeDataItemCancelled.connect(_storeCompletedCb);
        elfCloud.fetchDataItemStarted.connect(_transferStartedCb);
        elfCloud.fetchDataItemCompleted.connect(_fetchCompletedCb);
        elfCloud.fetchDataItemCancelled.connect(_fetchCompletedCb);

    }

    Component.onDestruction: {
        elfCloud.storeDataItemStarted.disconnect(_transferStartedCb);
        elfCloud.storeDataItemCompleted.disconnect(_storeCompletedCb);
        elfCloud.storeDataItemCancelled.disconnect(_storeCompletedCb);
        elfCloud.fetchDataItemStarted.disconnect(_transferStartedCb);
        elfCloud.fetchDataItemCompleted.disconnect(_fetchCompletedCb);
        elfCloud.fetchDataItemCancelled.disconnect(_fetchCompletedCb);

        if (_listStoredAsyncCallRef !== undefined)
            _listStoredAsyncCallRef.invalidate();

        if (_listFetchesAsyncCallRef !== undefined)
            _listFetchesAsyncCallRef.invalidate();
    }

    Column {
        id: uploadColumn
        anchors { fill: parent; margins: Theme.paddingMedium }

        Image {
            width: 86
            height: Theme.itemSizeMedium
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: "../icons/sailelfcloud_cover.png"
        }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: "image://theme/icon-s-cloud-upload"
            visible: uploadingLabel.visible
        }

        Label {
            id: uploadingLabel
            visible: false
            width: parent.width
            color: Theme.primaryColor
            horizontalAlignment: Text.AlignHCenter
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeLarge }
        }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: "image://theme/icon-s-cloud-download"
            visible: downloadingLabel.visible
        }

        Label {
            id: downloadingLabel
            visible: false
            width: parent.width
            color: Theme.primaryColor
            horizontalAlignment: Text.AlignHCenter
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeLarge }
        }

    }
}


