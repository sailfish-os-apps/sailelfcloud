import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.notifications 1.0
import harbour.sailelfcloud.helpers 1.0

ApplicationWindow
{
    id: application

    property string coverText: qsTr("elfCloud")
    property var elfCloud: ElfCloudAdapter { }
    property var helpers: Helpers { }

    Notification {
        id: uploadStartedNotif
        category: "x-nemo.transfer"
        summary: qsTr("File upload")
        body: qsTr("On progress")
        previewSummary: summary
        previewBody: body
    }

    Notification {
        id: uploadCompletedNotif
        category: "x-nemo.transfer.complete"
        summary: qsTr("File upload")
        body: qsTr("Compeleted")
        previewSummary: summary
        previewBody: body
    }

    Notification {
        id: uploadFileCompletedNotif
        category: "x-nemo.transfer.complete"
        summary: qsTr("File uploaded")
    }

    Notification {
        id: downloadStartedNotif
        category: "x-nemo.transfer"
        summary: qsTr("File download")
        previewSummary: summary
        previewBody: body
    }

    Notification {
        id: downloadFileCompletedNotif
        category: "x-nemo.transfer.complete"
        summary: qsTr("File downloaded")
        previewSummary: summary
        previewBody: body
    }

    Notification {
        id: downloadFileFailedNotif
        category: "x-nemo.transfer.complete"
        summary: qsTr("File download failed")
        previewSummary: summary
        previewBody: body
    }

    function _uploadStarted(parentId, remoteLocalNames) {
        uploadStartedNotif.publish();
    }

    function _uploadCompleted(parentId, remoteLocalNames) {
        uploadCompletedNotif.publish();
    }

    function uploadFileCompleted(parentId, remotePath, localPath) {
        console.debug("Uploaded", localPath, "to", parentId, ":", remotePath);
        uploadFileCompletedNotif.body = localPath;
        uploadFileCompletedNotif.replacesId = 0;
        uploadFileCompletedNotif.publish();
    }

    function _downloadStarted(parentId, dataItemName, localPath) {
        downloadStartedNotif.body = dataItemName;
        downloadStartedNotif.publish();
    }

    function _downloadCompleted(parentId, dataItemName, localPath) {
        downloadFileCompletedNotif.body = dataItemName;
        downloadFileCompletedNotif.publish();
    }

    function _downloadFailed(parentId, dataItemName, localPath, reason) {
        downloadFileFailedNotif.body = reason + " - " + dataItemName;
        downloadFileFailedNotif.publish();
    }



    Component.onCompleted: {
        elfCloud.fetchAndMoveDataItemStarted.connect(_downloadStarted);
        elfCloud.fetchAndMoveDataItemCompleted.connect(_downloadCompleted);
        elfCloud.fetchAndMoveDataItemFailed.connect(_downloadFailed);
        elfCloud.storeDataItemsStarted.connect(_uploadCompleted);
        elfCloud.storeDataItemsCompleted.connect(_uploadCompleted);
    }

    initialPage: Qt.resolvedUrl("pages/MainPage.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
}


