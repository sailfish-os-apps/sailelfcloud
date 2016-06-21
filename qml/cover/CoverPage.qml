import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

CoverBackground {

    property string location
    property int _uploadPercentage: 0
    property int _downloadPercentage: 0


    function _downloadCompleted(parentId, dataItemName, localPath) {
        _downloadPercentage = 0;
    }

    function _downloadChunkCompleted(parentId, name, totalSize, fetchedSize) {
        _downloadPercentage = Math.ceil((fetchedSize / totalSize) * 100);
        percentageRefreshTimer.running = true;
    }

    function _uploadCompleted(parentId, remoteLocalNames) {
        _uploadPercentage = 0;
    }

    function _uploadChunkCompleted(parentId, remoteName, localName, totalSize, storedSize) {
        _uploadPercentage = Math.ceil((storedSize / totalSize) * 100);
        percentageRefreshTimer.running = true;
    }

    Component.onCompleted: {
        elfCloud.fetchAndMoveDataItemCompleted.connect(_downloadCompleted);
        elfCloud.fetchAndMoveDataItemFailed.connect(_downloadCompleted);
        elfCloud.fetchDataItemChunkCompleted.connect(_downloadChunkCompleted);
        elfCloud.storeDataItemsCompleted.connect(_uploadCompleted);
        elfCloud.storeDataItemChunkCompleted.connect(_uploadChunkCompleted);
    }

    Component.onDestruction: {
        elfCloud.fetchAndMoveDataItemCompleted.disconnect(_downloadCompleted);
        elfCloud.fetchAndMoveDataItemFailed.disconnect(_downloadCompleted);
        elfCloud.fetchDataItemChunkCompleted.disconnect(_downloadChunkCompleted);
        elfCloud.storeDataItemsCompleted.disconnect(_uploadCompleted);
        elfCloud.storeDataItemChunkCompleted.disconnect(_uploadChunkCompleted);
    }

    Timer
    {
        id: percentageRefreshTimer
        interval: 3 * 1000
        repeat: true
        running: false
        onTriggered:
        {
            downloadingLabel.text = _downloadPercentage + "%";
            uploadingLabel.text = _uploadPercentage + "%";
            downloadingLabel.visible = (_downloadPercentage > 0);
            uploadingLabel.visible = (_uploadPercentage > 0);
            running = (_downloadPercentage > 0 || _uploadPercentage > 0);
        }
    }

    Column {
        id: uploadColumn
        anchors { fill: parent; margins: Theme.paddingMedium }

        Image {
            width: 86
            height: 86
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: "../icons/sailelfcloud_cover.png"
        }

        Label {
            id: locationLabel
            width: parent.width
            horizontalAlignment: Text.AlignLeft
            color: Theme.highlightColor
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
            truncationMode: TruncationMode.Fade
            text: location
        }

        Label {
            width: parent.width
            color: Theme.secondaryColor
            horizontalAlignment: Text.AlignHCenter
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeMedium }
            text: qsTr("Upload")
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

        Label {
            width: parent.width
            color: Theme.secondaryColor
            horizontalAlignment: Text.AlignHCenter
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeMedium }
            text: qsTr("Download")
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


