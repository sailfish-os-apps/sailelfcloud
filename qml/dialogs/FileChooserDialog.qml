import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.sailelfcloud.helpers 1.0
import "../views"

Dialog {

    property var     selectedPaths: []

    id: page
    objectName: "selectPicture"
    canAccept: false

    Helpers { id: helpers }

    DialogHeader {
        id: title
        title: qsTr("Choose source")
    }

    onAccepted: {
        if (imageView.visible === true) {
            selectedPaths = imageView.getSelectedPaths();
        } else if (documentView.visible === true) {
            selectedPaths = documentView.getSelectedPaths();
        } else if (musicView.visible === true) {
            selectedPaths = musicView.getSelectedPaths();
        } else if (videosView.visible === true) {
            selectedPaths = videosView.getSelectedPaths();
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.top: title.bottom
        anchors.bottom: page.bottom
        anchors.left: page.left
        anchors.right: page.right
        clip: true

        PullDownMenu {
            MenuItem {
                text: qsTr("Images")
                onClicked: {
                    title.title = qsTr("Choose images");
                    imageView.populate()
                    imageView.visible = true;
                    documentView.visible = musicView.visible = videosView.visible = false;
                }
            }
            MenuItem {
                text: qsTr("Documents")
                onClicked: {
                    title.title = qsTr("Choose documents");
                    documentView.populate()
                    documentView.visible = true;
                    imageView.visible = musicView.visible = videosView.visible = false;
                }
            }
            MenuItem {
                text: qsTr("Music")
                onClicked: {
                    title.title = qsTr("Choose music");
                    musicView.populate()
                    musicView.visible = true;
                    imageView.visible = documentView.visible = videosView.visible = false;
                }
            }
            MenuItem {
                text: qsTr("Videos")
                onClicked: {
                    title.title = qsTr("Choose videos");
                    videosView.populate()
                    videosView.visible = true;
                    musicView.visible = imageView.visible = documentView.visible = false;
                }
            }
        }

        ViewPlaceholder {
            id: noSourceSelected
            enabled: !imageView.visible && !documentView.visible && !musicView.visible && !videosView.visible
            text: qsTr("Pull down to choose source")
        }

        ImageSelectorView {
            id: imageView
            anchors.fill: parent
            visible: false
            onSelected: { page.canAccept = true; }
            onDeselected: { page.canAccept = false; }
        }

        FileSelectorView {
            id: documentView
            rootPath: StandardPaths.documents
            anchors.fill: parent
            visible: false
            onSelected: { page.canAccept = true; }
            onDeselected: { page.canAccept = false; }
        }

        FileSelectorView {
            id: musicView
            rootPath: StandardPaths.music
            anchors.fill: parent
            visible: false
            onSelected: { page.canAccept = true; }
            onDeselected: { page.canAccept = false; }
        }

        FileSelectorView {
            id: videosView
            rootPath: StandardPaths.videos
            anchors.fill: parent
            visible: false
            onSelected: { page.canAccept = true; }
            onDeselected: { page.canAccept = false; }
        }

    }
}
