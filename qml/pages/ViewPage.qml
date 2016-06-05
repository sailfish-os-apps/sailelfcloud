import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    allowedOrientations: Orientation.All
    property string filename: ""
    property string cloudFilename: ""


    function _updateTextView(type, text) {
        messageLabel.text = text;
        portraitText.text = type;
        landscapeText.text = type;

        if (type === "bin") {
            messageLabel.wrapMode = Text.NoWrap;
            messageLabel.font.family = "Monospace"
        }
        flickableForText.visible = true;
    }

    function _readPlainFile(filename) {
        elfCloud.readFile(filename, _updateTextView);
    }

    function _readImageFile(filename) {
        console.log("showing image", filename);
        image.source = filename;
        flickableForImage.visible = true;
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

            PageHeader { title: page.cloudFilename }

            Label {
                id: portraitText
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.secondaryColor
                visible: page.orientation === Orientation.Portrait ||
                         page.orientation === Orientation.PortraitInverted
            }
            Label {
                id: landscapeText
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.secondaryColor
                visible: page.orientation === Orientation.Landscape ||
                         page.orientation === Orientation.LandscapeInverted
            }
            Spacer {
                height: 2*Theme.paddingLarge
                visible: messageLabel.text !== ""
            }
            Label {
                id: messageLabel
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                // show medium size if there is no portrait (or landscape text)
                // in that case, this message becomes main message
                font.pixelSize: portraitText.text === "" ? Theme.fontSizeMedium : Theme.fontSizeTiny
                color: portraitText.text === "" ? Theme.highlightColor : Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter
            }
            Spacer {
                height: 2*Theme.paddingLarge
                visible: messageLabel.text !== ""
            }
        }
        HorizontalScrollDecorator { flickable: flickableForText }
    }


    SilicaFlickable {
        id: flickableForImage
        visible: false
        anchors.fill: parent

        VerticalScrollDecorator { flickable: flickableForImage }

        PageHeader { title: page.cloudFilename }

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

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            var mime = helpers.getFileMimeType(filename);
            if (mime === "text/plain")
                _readPlainFile(filename);
            else if (mime.indexOf("image/") >= 0)
                _readImageFile(filename);
        }
    }
}


