import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"

SilicaFlickable {
    id: viewer
    clip: true

    signal selected(var paths)

    function populate() {
        imageModel.clear();

        var paths = helpers.getStandardLocationPictures();

        for (var pathIdx = 0; pathIdx < paths.length; pathIdx++) {
            var files = helpers.getListOfFilesRecursively(paths[pathIdx]);

            for(var fileIdx = 0; fileIdx < files.length; fileIdx++) {
                imageModel.append({"path":files[fileIdx], "selected":false});
            }
        }
    }

    function _getSelectedPaths() {
        var selectedPaths = [];
        for (var i = 0; i < imageModel.count; i++) {
            var m = imageModel.get(i);
            if (m.selected)
                selectedPaths.push(m.path);
        }
        return selectedPaths;
    }

    function _isItemSelected(itemIndex) {
        return imageModel.get(itemIndex).selected;
    }

    function _selectItem(itemIndex) {
        imageModel.setProperty(itemIndex, "selected", true);
    }

    function _deselectItem(itemIndex) {
        imageModel.setProperty(itemIndex, "selected", false);
    }

    function selectAll() {
        for (var i = 0; i < imageModel.count; i++) {
            imageModel.setProperty(i, "selected", true);
        }
        selected(_getSelectedPaths());
    }

    function clearSelection() {
        for (var i = 0; i < imageModel.count; i++) {
            imageModel.setProperty(i, "selected", false);
        }
        selected([]);
    }

    SilicaGridView {
        id: imageView
        anchors.fill: parent
        cellWidth: page.isPortrait ? (page.width / 4) : (page.width / 7)
        cellHeight: cellWidth
        cacheBuffer: cellHeight * 2

        model: ListModel { id: imageModel }

        delegate: ImageBackgroundItem {
            width: imageView.cellWidth - 1
            height: imageView.cellHeight - 1
            path: model.path
            selected: model.selected

            onClicked: {
                if (_isItemSelected(model.index))
                    _deselectItem(model.index);
                else
                    _selectItem(model.index);

                viewer.selected(_getSelectedPaths());
            }
        }
        VerticalScrollDecorator { flickable: imageView }
    }
}

