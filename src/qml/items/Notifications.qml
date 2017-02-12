import QtQuick 2.0
import org.nemomobile.notifications 1.0

Item {

    Notification {
        id: uploadStartedNotif
        category: "x-nemo.transfer"
        body: qsTr("Upload to cloud.")
        previewSummary: summary
        previewBody: body

        function publishWithName(name) { summary = name; publish(); }
    }

    Notification {
        id: uploadCompletedNotif
        category: "x-nemo.transfer.complete"
        body: qsTr("Upload completed.")
        previewSummary: summary
        previewBody: body

        function publishWithName(name) { summary = name; publish(); }
    }

    Notification {
        id: downloadStartedNotif
        category: "x-nemo.transfer"
        body: qsTr("Download from cloud.")
        previewSummary: summary
        previewBody: body

        function publishWithName(name) { summary = name; publish(); }
    }

    Notification {
        id: downloadCompletedNotif
        category: "x-nemo.transfer.complete"
        body: qsTr("Download completed.")
        previewSummary: summary
        previewBody: body

        function publishWithName(name) { summary = name; publish(); }
    }

    Notification {
        id: downloadFileFailedNotif
        category: "x-nemo.transfer.error.conf"
        previewSummary: summary
        previewBody: body
        urgency: Notification.Critical

        function publishWithNameAndReason(name, reason) {
            replacesId = 0; // ensure that existing failure notifications do not get replaced
            summary = name;
            body = qsTr("File download failed: ") + reason;
            publish();
        }
    }

    function _uploadStarted(parentId, remoteName, localName) {
        uploadStartedNotif.publishWithName(remoteName);
    }

    function _uploadCompleted(parentId, remoteName, localName) {
        uploadStartedNotif.close();
        uploadCompletedNotif.publishWithName(remoteName);
    }

    function _downloadStarted(parentId, remoteName, localName) {
        downloadStartedNotif.publishWithName(remoteName);
    }

    function _downloadCompleted(parentId, remoteName, localName) {
        downloadStartedNotif.close();
        downloadCompletedNotif.publishWithName(remoteName);
    }

    function _downloadFailed(parentId, remoteName, localName, reason) {
        downloadFileFailedNotif.publishWithNameAndReason(remoteName, reason)
    }

    Component.onCompleted: {
        elfCloud.storeDataItemStarted.connect(_uploadStarted);
        elfCloud.storeDataItemCompleted.connect(_uploadCompleted);
        elfCloud.fetchAndMoveDataItemStarted.connect(_downloadStarted);
        elfCloud.fetchAndMoveDataItemCompleted.connect(_downloadCompleted);
        elfCloud.fetchAndMoveDataItemFailed.connect(_downloadFailed)
        elfCloud.fetchDataItemFailed.connect(_downloadFailed)
    }

    Component.onDestruction: {
        elfCloud.storeDataItemStarted.disconnect(_uploadStarted);
        elfCloud.storeDataItemCompleted.disconnect(_uploadCompleted);
        elfCloud.fetchAndMoveDataItemStarted.disconnect(_downloadStarted);
        elfCloud.fetchAndMoveDataItemCompleted.disconnect(_downloadCompleted);
        elfCloud.fetchAndMoveDataItemFailed.disconnect(_downloadFailed)
        elfCloud.fetchDataItemFailed.disconnect(_downloadFailed)
    }

}
