import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.notifications 1.0
import "cover"

ApplicationWindow
{
    id: application

    property var elfCloud: ElfCloudAdapter { }
    property var keyHandler: KeyHandler { }

    function setItemNameToCover(name) {
        coverPage.location = name
    }

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
        category: "x-nemo.transfer.error.conf"
        summary: qsTr("File download failed")
        previewSummary: summary
        previewBody: body
    }

    function _uploadStarted() {
        uploadStartedNotif.publish();
    }

    function _uploadCompleted() {
        uploadCompletedNotif.publish();
        uploadFileCompletedNotif.close();
    }

    function _uploadFileCompleted(parentId, remoteName, localName, dataItemsLeft) {
        console.debug("Uploaded", localName, "to", parentId, ":", remoteName, " items left to upload ", dataItemsLeft);
        uploadFileCompletedNotif.body = helpers.getFilenameFromPath(localName) + qsTr(" uploaded, items left ") + dataItemsLeft;
        uploadFileCompletedNotif.previewBody  = helpers.getFilenameFromPath(localName);
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

    function _handleException(id, message) {
        pageStack.completeAnimation()
        pageStack.push(Qt.resolvedUrl("pages/ProblemPage.qml"),
                       {"id":id,
                        "message":message});
    }

    Component.onCompleted: {
        elfCloud.exceptionOccurred.connect(_handleException);
        elfCloud.fetchAndMoveDataItemStarted.connect(_downloadStarted);
        elfCloud.fetchAndMoveDataItemCompleted.connect(_downloadCompleted);
        elfCloud.fetchAndMoveDataItemFailed.connect(_downloadFailed);
        elfCloud.storeDataItemsStarted.connect(_uploadCompleted);
        elfCloud.storeDataItemsCompleted.connect(_uploadCompleted);
        elfCloud.storeDataItemCompleted.connect(_uploadFileCompleted);
    }

    initialPage: Qt.resolvedUrl("pages/MainPage.qml")
    cover: CoverPage {
        id: coverPage
    }

    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
}


