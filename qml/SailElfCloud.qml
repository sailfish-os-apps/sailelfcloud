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

    function uploadStarted() {
        uploadStartedNotif.publish();
    }

    function uploadCompleted() {
        uploadCompletedNotif.publish();
    }

    function uploadFileCompleted(parentId, remotePath, localPath) {
        console.debug("Uploaded", localPath, "to", parentId, ":", remotePath);
        uploadFileCompletedNotif.body = localPath;
        uploadFileCompletedNotif.replacesId = 0;
        uploadFileCompletedNotif.publish();
    }

    function downloadFileCompleted(parentId, dataItemName, localPath) {
        console.debug("Downloaded", localPath, "to", parentId, ":", dataItemName);
        elfCloud.downloadFileCompleted.disconnect(downloadFileCompleted);

        if (helpers.moveAndRenameFileAccordingToMime(localPath, dataItemName)) {
            downloadFileCompletedNotif.summary = qsTr("File exists")
            downloadFileCompletedNotif.body = dataItemName;
            downloadFileCompletedNotif.publish();
        } else {
            downloadFileCompletedNotif.body = dataItemName;
            downloadFileCompletedNotif.publish();
        }
    }

    Component.onCompleted: {
        elfCloud.uploadStarted.connect(uploadStarted);
        elfCloud.uploadCompleted.connect(uploadCompleted);
        elfCloud.uploadFileCompleted.connect(uploadFileCompleted);
    }

    initialPage: Qt.resolvedUrl("pages/MainPage.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
}


