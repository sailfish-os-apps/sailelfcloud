import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

CoverBackground {

    property string location
    property int uploadPercentage
    property int downloadPercentage


    function _downloadCompleted(parentId, dataItemName, localPath) {
        percentageRefreshTimer.restart() // Keep visible one interval
        coverPage.downloadPercentage = 0;
    }

    function _downloadChunkCompleted(parentId, name, totalSize, sizeFetched) {
        downloadPercentage = Math.round((sizeFetched / totalSize) * 100);
    }


    Component.onCompleted: {
        elfCloud.fetchAndMoveDataItemCompleted.connect(_downloadCompleted);
        elfCloud.fetchAndMoveDataItemFailed.connect(_downloadCompleted);
        elfCloud.fetchDataItemChunkCompleted.connect(_downloadChunkCompleted);
    }

    Component.onDestruction: {
        elfCloud.fetchAndMoveDataItemCompleted.disconnect(_downloadCompleted);
        elfCloud.fetchAndMoveDataItemFailed.disconnect(_downloadCompleted);
        elfCloud.fetchDataItemChunkCompleted.disconnect(_downloadChunkCompleted);
    }

    Timer
    {
        id: percentageRefreshTimer
        interval: 3 * 1000
        repeat: true
        running: uploadPercentage > 0 || downloadPercentage > 0
        onTriggered:
        {
            if (downloadPercentage > 0)
                downloadingLabel.text = downloadPercentage + "%";

            if (uploadPercentage > 0)
                uploadingLabel.text = uploadPercentage + "%";
        }
    }

    Timer
    {
        id: locationScrollerTimer
        interval: 200
        repeat: true
        running: !!location
        onTriggered:
        {
            if (locationLabel.truncated)
                locationLabel.anchors.horizontalCenterOffset += 5;
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
            visible: !!uploadingLabel.text
        }

        Label {
            id: uploadingLabel
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
            visible: !!downloadingLabel.text
        }

        Label {
            id: downloadingLabel
            width: parent.width
            color: Theme.primaryColor
            horizontalAlignment: Text.AlignHCenter
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeLarge }
        }

    }
}


