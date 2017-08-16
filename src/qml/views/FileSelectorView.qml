import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaFlickable {
    id: viewer
    clip: true

    property var rootPaths: undefined

    signal selected(var paths)

    function populate() {
        fileModel.clear();

        for (var pathIdx = 0; pathIdx < rootPaths.length; pathIdx++) {
            console.log("Path:", rootPaths[pathIdx]);
            var files = helpers.getListOfFilesRecursively(rootPaths[pathIdx]);

            for(var fileIdx = 0; fileIdx < files.length; fileIdx++) {
                fileModel.append({"path":files[fileIdx],
                                  "filename":helpers.getFilenameFromPath(files[fileIdx]),
                                  "selected":false});
            }
        }
    }

    function _getSelectedPaths() {
        var selectedPaths = [];
        for (var i = 0; i < fileModel.count; i++) {
            var m = fileModel.get(i);
            if (m.selected)
                selectedPaths.push(m.path);
        }
        return selectedPaths;
    }

    function _isItemSelected(itemIndex) {
        return fileModel.get(itemIndex).selected;
    }

    function _selectItem(itemIndex) {
        fileModel.setProperty(itemIndex, "selected", true);
    }

    function _deselectItem(itemIndex) {
        fileModel.setProperty(itemIndex, "selected", false);
    }

    function _getIconForFileMimeType(path) {
        var mime = helpers.getFileMimeType(path);

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

    function selectAll() {
        for (var i = 0; i < fileModel.count; i++) {
            fileModel.setProperty(i, "selected", true);
        }
        selected(_getSelectedPaths());
    }

    function clearSelection() {
        for (var i = 0; i < fileModel.count; i++) {
            fileModel.setProperty(i, "selected", false);
        }
        selected([]);
    }

    SilicaListView {
        id: fileView
        anchors.fill: parent

        model: ListModel { id: fileModel }

        delegate: ListItem {

            highlighted: model.selected

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
                source: viewer._getIconForFileMimeType(model.path)
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
                text: qsTr("Size: ") + helpers.getFileSize(model.path)
            }

            onClicked: {
                if (viewer._isItemSelected(model.index))
                    viewer._deselectItem(model.index);
                else
                    viewer._selectItem(model.index);

                viewer.selected(_getSelectedPaths());
            }
        }

        VerticalScrollDecorator { flickable: fileView }
    }
}

