import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"

SilicaFlickable {
    id: viewer
    clip: true

    property var    _selectedItems: []

    signal selected()
    signal deselected()

    function populate() {
        console.info("Image location:", StandardPaths.pictures);
        imageModel.clear();
        var files = helpers.getListOfFilesRecursively(StandardPaths.pictures);
        for(var fileIdx = 0; fileIdx < files.length; fileIdx++) {
            console.info("File", files[fileIdx]);
            imageModel.append({"path":files[fileIdx]});
        }
    }

    function getSelectedPaths() {
        var selectedPaths = [];
        for (var i = 0; i < _selectedItems.length; i++) {
            var m = imageModel.get(_selectedItems[i]);
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

            onClicked: {
                if (isItemSelected(model.index)) {
                    deselectItem(model.index);
                    selected(false);
                    viewer.deselected();
                }
                else {
                    selectItem(model.index);
                    selected(true);
                    viewer.selected();
                }
            }
        }
        VerticalScrollDecorator { flickable: imageView }
    }
}

