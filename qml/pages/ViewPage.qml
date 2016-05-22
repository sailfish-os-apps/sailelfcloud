import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    allowedOrientations: Orientation.All
    property string filename: ""
    property string cloudFilename: ""

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

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
                visible: message.text !== ""
            }
            Label {
                id: message
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                // show medium size if there is no portrait (or landscape text)
                // in that case, this message becomes main message
                font.pixelSize: portraitText.text === "" ? Theme.fontSizeMedium : Theme.fontSizeTiny
                color: portraitText.text === "" ? Theme.highlightColor : Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter
                visible: message.text !== ""
            }
            Spacer {
                height: 2*Theme.paddingLarge
                visible: message.text !== ""
            }

            HorizontalScrollDecorator { flickable: flickable }
        }
    }

    function updateTextView(type, text) {
        message.text = text;
        portraitText.text = type;
        landscapeText.text = type;

        if (type === "bin") {
            message.wrapMode = Text.NoWrap;
            message.font.family = "Monospace"
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            elfCloud.readFile(filename, updateTextView);
        }
    }
}


