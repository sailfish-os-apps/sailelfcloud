import QtQuick 2.0
import Sailfish.Silica 1.0
import "../views"

Dialog {

    property var selectedPaths: []

    id: page
    objectName: "selectPicture"
    canAccept: selectedPaths.length > 0

    DialogHeader {
        id: title
        title: qsTr("Choose source")
    }

    ListModel {
        id: fileSelectorModel
    }

    Component.onCompleted: {
        fileSelectorModel.append({"path":StandardPaths.documents,
                                     "text":qsTr("Documents"),
                                     "title":qsTr("Choose documents")});
        fileSelectorModel.append({"path":StandardPaths.music,
                                     "text":qsTr("Music"),
                                     "title":qsTr("Choose music")});
        fileSelectorModel.append({"path":StandardPaths.videos,
                                     "text":qsTr("Videos"),
                                     "title":qsTr("Choose videos")});
        fileSelectorModel.append({"path":helpers.getStandardLocationDownloads(),
                                     "text":qsTr("Downloads"),
                                     "title":qsTr("Choose files")});

    }

    function _hideAllSelectors() {
        for (var index = 0; index < fileSelectorRepeater.count; index++) {
            var fileSelector = fileSelectorRepeater.itemAt(index);
            fileSelector.visible = false;
        }
        imageView.visible = false;
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
                    _hideAllSelectors();
                    title.title = qsTr("Choose images");
                    imageView.populate()
                    imageView.visible = true;
                    noSourceSelected.visible = false;
                }
            }

            Repeater {
                model: fileSelectorModel

                delegate: MenuItem {
                    text: model.text
                    onClicked: {
                        _hideAllSelectors();
                        title.title = model.title;
                        var fileSelector = fileSelectorRepeater.itemAt(index);
                        fileSelector.populate();
                        fileSelector.visible = true;
                        noSourceSelected.visible = false;
                    }
                }
            }

        }

        ViewPlaceholder {
            id: noSourceSelected
            enabled: false
            text: qsTr("Pull down to choose source")
        }

        ImageSelectorView {
            id: imageView
            anchors.fill: parent
            visible: false
            onSelected: { selectedPaths = paths; }
        }

        Repeater {
            id: fileSelectorRepeater
            model: fileSelectorModel
            delegate: FileSelectorView {
                rootPath: model.path
                anchors.fill: parent
                visible: false
                onSelected: { selectedPaths = paths; }
            }
        }
    }
}
