import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    allowedOrientations: Orientation.All

    property string dataItemName
    property int parentContainerId

    function _displayUnknownFile(mime) {
        busyIndication.running = false;
        unknownFileMimeArea.text = qsTr("File mime type is not supported by this view") + ": " + mime;
        unknownFileMimeArea.visible = true;
    }

    function _displayImageFile(filename) {
        image.source = filename;
        busyIndication.running = false;
        flickableForImage.visible = true;
    }

    function _updateTextViewForPlainFile(text, mime) {
        fileContentLabel.text = text;
        fileContentLabel.font.pixelSize = Theme.fontSizeMedium
        fileContentLabel.color = Theme.highlightColor
        mimeLabel.text = mime;
        busyIndication.running = false;
        flickableForText.visible = true;
    }

    function _displayPlainFile(filename, mime) {
        _updateTextViewForPlainFile(helpers.readPlainFile(filename), mime);
    }

    function _displayFile(localFilename) {
        var mime = helpers.getFileMimeType(localFilename);
        console.debug("File:", localFilename, "mime type is", mime);

        if (mime === "text/plain")
            _displayPlainFile(localFilename, mime);
        else if (mime.indexOf("image/") >= 0)
            _displayImageFile(localFilename);
        else
            _displayUnknownFile(mime);
    }

    function _fetchAndDisplayDataItem() {
        var outputPath = helpers.generateLocalPathForRemoteDataItem(parentContainerId, dataItemName);
        console.debug("Fetching", dataItemName, "from", parentContainerId, "to", outputPath);
        elfCloud.fetchData(parentContainerId, dataItemName, outputPath,
                           function(status) { _displayFile(outputPath); });
    }

    Component.onCompleted: {
        _fetchAndDisplayDataItem();
    }

    BusyIndicator {
        id: busyIndication
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: true
    }

    TextArea {
        id: unknownFileMimeArea
        anchors.fill: parent
        verticalAlignment: TextEdit.AlignVCenter
        horizontalAlignment: TextEdit.AlignHCenter
        textMargin: width / 8
        labelVisible: false
        readOnly: true
        wrapMode: TextEdit.Wrap
        visible: false
    }

    SilicaFlickable {
        id: flickableForText
        visible: false
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator { flickable: flickableForText }

        Column {
            id: column
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            PageHeader { title: dataItemName }

            Label {
                id: mimeLabel
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.secondaryColor
            }
            Spacer {
                height: 2*Theme.paddingLarge
            }
            Label {
                id: fileContentLabel
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignLeft
            }
            Spacer {
                height: 2*Theme.paddingLarge
            }
        }
        HorizontalScrollDecorator { flickable: flickableForText }
    }


    SilicaFlickable {
        id: flickableForImage
        visible: false
        anchors.fill: parent

        VerticalScrollDecorator { flickable: flickableForImage }

        PageHeader { title: dataItemName }

        Image {
            id: image
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            sourceSize.height: page.height * 2

            PinchArea {
                anchors.fill: parent
                pinch.target: parent
                pinch.minimumScale: 1
                pinch.maximumScale: 4
            }
        }

        HorizontalScrollDecorator { flickable: flickableForImage }
    }
}


