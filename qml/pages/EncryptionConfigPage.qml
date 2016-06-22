import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    function _createNewKey(hash) {
    }

    function _createNewKeyFromFile() {
    }

    function _createKey(index) {
        switch (index) {
        case 2:
            var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/ImportFromClipboardDialog.qml"));
            dialog.createdKey.connect(_createNewKey);
            break;
        }
    }

    function _addKeysToList() {
        var keys = keyHandler.getKeys();

        for (var i = 0; i < keys.length; i++) {
            console.log("appending", keys[i]['name'])
            keyListMode.append({"key": keys[i], "active": false});
        }
    }

    function _clearActiveKey() {
        for(var index = 0; index < keyListMode.count; index++) {
            var item = keyListMode.get(index);
            item['active'] = false;
            keyListMode.set(index, item); // Setting same item back to model updates the list
        }
    }

    function _chooseActiveKey(index) {
        _clearActiveKey();
        var item = keyListMode.get(index)
        item['active'] = true;
        keyListMode.set(index, item); // Setting same item back to model updates the list
        helpers.setActiveKey(item['key']['hash']);
    }

    function _setActiveKeyFromConfig() {
        var hash = helpers.getActiveKey();
        for(var index = 0; index < keyListMode.count; index++) {
            var item = keyListMode.get(index);
            if (item['key']['hash'] === helpers.getActiveKey())
                _chooseActiveKey(index);
        }
    }

    Component.onCompleted: {
        _addKeysToList();
        _setActiveKeyFromConfig();
    }


    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        id: flickable
        anchors.fill: parent

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column
            anchors.fill: parent
            spacing: Theme.paddingLarge

            PageHeader {
                id: pageHeader
                title: qsTr("Encryption configurations")
            }

            SectionHeader {
                id: keyCreationSectionHeader
                text: qsTr("Encryption key creation")
            }
            Row {
                id: keyCreationRow
                spacing: Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: qsTr("Create")
                    onClicked: _createKey(source.currentIndex)
                }

                ComboBox {
                    id: source
                    width: page.width / 2

                    menu: ContextMenu {
                        MenuItem { id: brandNew; text: qsTr("New") }
                        MenuItem { id: file; text: qsTr("From file") }
                        MenuItem { id: clipboard; text: qsTr("From clip-board") }
                    }
                }
            }
            SectionHeader {
                id: keysSectionHeader
                text: qsTr("Available encryption keys")
            }
            SilicaListView {
                anchors { left: parent.left; right: parent.right }
                width: parent.width
                spacing: Theme.paddingSmall
                height: flickable.height - pageHeader.height -
                        keyCreationSectionHeader.height -
                        keyCreationRow.height - keysSectionHeader.height - Theme.itemSizeSmall
                clip: true // prevents overlapping keysSectionHeader

                model: ListModel {
                    id: keyListMode
                }

                delegate: ListItem {
                    width: ListView.view.width
                    height: name.height + description.height + hash.height
                    contentHeight: name.height + description.height + hash.height

                    IconButton {
                        id: favoriteImage
                        icon.source: model.active ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                        onClicked: { _chooseActiveKey(index); }
                    }

                    Label {
                        id:name
                        anchors { left: favoriteImage.right; leftMargin: Theme.paddingSmall }
                        text: model.key["name"]
                    }
                    Label {
                        id:description
                        anchors { left: favoriteImage.right; top: name.bottom; topMargin: Theme.paddingSmall }
                        font { weight: Font.Light; pixelSize: Theme.fontSizeTiny }
                        wrapMode: Text.WordWrap
                        truncationMode: TruncationMode.Fade
                        maximumLineCount: 2
                        text: model.key["description"]
                    }
                    Label {
                        id: hash
                        anchors { left: favoriteImage.right; top: description.bottom; topMargin: Theme.paddingSmall }
                        text: model.key["hash"]
                        font { weight: Font.Light; pixelSize: Theme.fontSizeTiny }
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }
}


