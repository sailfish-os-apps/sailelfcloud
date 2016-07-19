import QtQuick 2.0
import Sailfish.Silica 1.0
import "../views"

Dialog {

    property var selectedPaths: []
    property var _activeFileSelector: undefined

    id: page
    objectName: "selectPicture"
    canAccept: selectedPaths.length > 0

    DialogHeader {
        id: dialogHeader
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
        for (var index = 0; index < fileSelectorRepeater.count; index++)
            fileSelectorRepeater.itemAt(index).visible = false;
        imageView.visible = false;
    }

    function _selectAll() {
        if (_activeFileSelector) {
            _activeFileSelector.selectAll();
        }
    }

    function _clearSelection() {
        if (_activeFileSelector) {
            _activeFileSelector.clearSelection();
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.top: dialogHeader.bottom
        anchors.bottom: page.bottom
        anchors.left: page.left
        anchors.right: page.right
        clip: true

        PullDownMenu {
            MenuItem {
                text: qsTr("Images")
                onClicked: {
                    _hideAllSelectors();
                    dialogHeader.title = qsTr("Choose images");
                    _activeFileSelector = imageView;
                    imageView.populate()
                    imageView.visible = true;
                    noSourceSelected.visible = false;
                    selectedPaths = [];
                }
            }

            Repeater {
                model: fileSelectorModel

                delegate: MenuItem {
                    text: model.text
                    onClicked: {
                        _hideAllSelectors();
                        dialogHeader.title = model.title;
                        _activeFileSelector = fileSelectorRepeater.itemAt(index);
                        _activeFileSelector.populate();
                        _activeFileSelector.visible = true;
                        noSourceSelected.visible = false;
                        selectedPaths = [];
                    }
                }
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Select all")
                onClicked: _selectAll()
                enabled: !!_activeFileSelector
            }
            MenuItem {
                text: qsTr("Clear selection")
                onClicked: _clearSelection()
                enabled: !!_activeFileSelector
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
