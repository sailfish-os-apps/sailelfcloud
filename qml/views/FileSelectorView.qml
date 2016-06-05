import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaFlickable {
    id: viewer
    clip: true

    property var rootPath: null
    property var _selectedItems: []

    signal selected()
    signal deselected()

    function populate() {
        console.info("Root location:", rootPath);
        fileModel.clear();
        var files = helpers.getListOfFilesRecursively(rootPath);
        for(var fileIdx = 0; fileIdx < files.length; fileIdx++) {
            console.info("File", files[fileIdx]);
            fileModel.append({"path":files[fileIdx],
                              "filename":helpers.getFilenameFromPath(files[fileIdx])});
        }
    }

    function getSelectedPaths() {
        var selectedPaths = [];
        for (var i = 0; i < _selectedItems.length; i++) {
            var m = fileModel.get(_selectedItems[i]);
            console.info("File for upload:", m.path)
            selectedPaths.push(m.path);
        }

        return selectedPaths;
    }

    function isItemSelected(itemIndex) {
        for (var i = 0; i < _selectedItems.length; i++) {
            if (_selectedItems[i] === itemIndex)
                return true;
        }
        return false;
    }

    function selectItem(itemIndex) {
        _selectedItems.push(itemIndex);
    }

    function deselectItem(itemIndex) {
        for (var i = 0; i < _selectedItems.length; i++) {
            if (_selectedItems[i] === itemIndex) {
                _selectedItems.splice(i, 1);
                return;
            }
        }
    }

    function isSelectedItems() {
        return _selectedItems.length > 0;
    }

    function getIconForFileMimeType(path) {
        var mime = helpers.getFileMimeType(path);
        console.debug(path + ";" + mime);

        if (mime === "text/plain") {
            return "image://theme/icon-m-document";
        } else if (mime.indexOf("image/") >= 0) {
            return path;
        } else if (mime.indexOf("audio/") >= 0) {
            return "image://theme/icon-m-music";
        }else if (mime.indexOf("video/") >= 0) {
            return "image://theme/icon-m-video";
        } else {
            return "image://theme/icon-m-other";
        }
    }

    SilicaListView {
        id: fileView
        anchors.fill: parent

        model: ListModel { id: fileModel }

        delegate: ListItem {
            Image {
                id: listIcon
                x: Theme.paddingLarge
                y: Theme.paddingMedium
                width: Theme.iconSizeMedium
                height: Theme.iconSizeMedium
                sourceSize.width: width
                sourceSize.height: height
                clip: true
                smooth: true
                cache: true
                asynchronous: true
                source: viewer.getIconForFileMimeType(model.path)
            }
            Label {
                id: labelContentName
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                color: Theme.primaryColor
                text: model.filename
            }
            Label {
                anchors.top: labelContentName.bottom
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: "Size: " + helpers.getFileSize(model.path)
            }

            onClicked: {
                if (viewer.isItemSelected(model.index)) {
                    viewer.deselectItem(model.index);
                    highlighted = false;
                }
                else {
                    viewer.selectItem(model.index);
                    highlighted = true;
                }

                if (viewer.isSelectedItems()) {
                    viewer.selected();
                }
                else {
                    viewer.deselected();
                }
            }
        }
        VerticalScrollDecorator { flickable: fileView }
    }
}

