import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    allowedOrientations: Orientation.All

    property string dataItemName
    property int parentContainerId


    Component.onCompleted: {
        console.debug("Fetching", dataItemName, "from", parentContainerId);
        elfCloud.fetchData(parentContainerId, dataItemName, _displayFile);
    }

    function _displayFile(localFilename) {
        var mime = helpers.getFileMimeType(localFilename);
        console.debug("File:", localFilename, "mime type is", mime);

        if (mime === "text/plain")
            _displayPlainFile(localFilename, mime);
        else if (mime.indexOf("image/") >= 0)
            _displayImageFile(localFilename);
        else if (mime === "application/octet-stream")
            _displayBinFile(localFilename, mime);
        else
            _displayUnknownFile(mime);
    }

    function _displayPlainFile(filename, mime) {
        elfCloud.readPlainFile(filename,
                               function(text) { _updateTextViewForPlainFile(text, mime); });
    }

    function _updateTextViewForPlainFile(text, mime) {
        fileContentLabel.text = text;
        fileContentLabel.font.pixelSize = Theme.fontSizeMedium
        fileContentLabel.color = Theme.highlightColor
        mimeLabel.text = mime;
        busyIndication.running = false;
        flickableForText.visible = true;
    }

    function _displayImageFile(filename) {
        image.source = filename;
        busyIndication.running = false;
        flickableForImage.visible = true;
    }

    function _displayBinFile(filename, mime) {
        elfCloud.readBinFile(filename,
                             function(text) { _updateTextViewForBinFile(text, mime); });
    }

    function _updateTextViewForBinFile(text, mime) {
        fileContentLabel.text = text;
        fileContentLabel.wrapMode = Text.NoWrap;
        fileContentLabel.font.family = "Monospace";
        fileContentLabel.font.pixelSize = Theme.fontSizeTiny
        fileContentLabel.color = Theme.secondaryColor
        mimeLabel.text = mime;
        busyIndication.running = false;
        flickableForText.visible = true;
    }

    function _displayUnknownFile(mime) {
        busyIndication.running = false;
        unknownFileMimeArea.text = qsTr("File mime type is not supported by this view") + ": " + mime;
        unknownFileMimeArea.visible = true;
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


