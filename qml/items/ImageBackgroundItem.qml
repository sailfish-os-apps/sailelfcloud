import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.sailelfcloud.helpers 1.0

BackgroundItem {
    id: item

    property string path
    signal selected(bool state)

    onSelected: {
        selectedMarker.visible = state;
    }

    Image {
        id: image
        source: path
        height: parent.height
        width: parent.width
        sourceSize.height: parent.height
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectCrop
        clip: true
        smooth: true
        cache: true
        asynchronous: true

        states: [
            State {
                name: 'loaded'; when: image.status == Image.Ready
                PropertyChanges { target: image; opacity: 1; }
            },
            State {
                name: 'loading'; when: image.status != Image.Ready
                PropertyChanges { target: image; opacity: 0; }
            }
        ]

        Behavior on opacity {
            FadeAnimation {}
        }
    }

    Rectangle {
        id: selectedMarker
        anchors.fill: parent
        color: Theme.highlightColor
        visible: false
        opacity: 0.5
    }
    Rectangle {
        id: rec
        color: Theme.secondaryHighlightColor
        height: Theme.fontSizeExtraSmall
        width: parent.width
        anchors.bottom: parent.bottom
        opacity: parent.pressed ? 1.0 : 0.6
    }

    Label {
        anchors.fill: rec
        anchors.margins: 3
        font.pixelSize: Theme.fontSizeExtraSmall
        text: helpers.getFilenameFromPath(path)
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
        horizontalAlignment : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Theme.primaryColor
    }
}
