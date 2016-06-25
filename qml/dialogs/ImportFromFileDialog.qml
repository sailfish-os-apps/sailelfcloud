import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    property string name

    signal createdKey(string hash)

    function addKeyFilesToList() {
        var keyFilesInDocuments = keyHandler.findKeyFiles(helpers.getStandardLocationDocuments());
        var keyFilesInDownloads = keyHandler.findKeyFiles(helpers.getStandardLocationDownloads());

        for (var i = 0; i < keyFilesInDocuments.length; i++) {
            var keyInfo = keyHandler.readKeyInfoFromFile(keyFilesInDocuments[i]);
            keyListModel.append({'filename':helpers.getFilenameFromPath(keyFilesInDocuments[i]),
                                    'path':keyFilesInDocuments[i],
                                    'name':keyInfo['name'],
                                    'description':keyInfo['description'],
                                    'hash':keyInfo['hash'],
                                    'location':'documents'});
        }

        for (var i = 0; i < keyFilesInDownloads.length; i++) {
            var keyInfo = keyHandler.readKeyInfoFromFile(keyFilesInDownloads[i]);
            keyListModel.append({'filename':helpers.getFilenameFromPath(keyFilesInDownloads[i]),
                                    'path':keyFilesInDownloads[i],
                                    'name':keyInfo['name'],
                                    'description':keyInfo['description'],
                                    'hash':keyInfo['hash'],
                                    'location':'downloads'});
        }
    }

    Component.onCompleted: {
        addKeyFilesToList();
    }

    function _canAcceptSelection(index) {

        if (index !== -1) {
            var hash = keyListModel.get(index).hash;

            if (keyHandler.isKey(hash)) {
                keyExistsText.visible = true;
                canAccept = false;
            } else {
                keyExistsText.visible = false;
                canAccept = true;
            }

        } else {
            canAccept = false;
        }
    }

    function _create(path) {
        var keyInfo = keyHandler.readKeyInfoFromFile(path);
        keyHandler.storeKey(keyInfo['name'], keyInfo['description'],
                            keyInfo['key'], keyInfo['iv'], keyInfo['hash']);
        createdKey(keyInfo['hash']);
    }

    DialogHeader {
        id: header
        title: qsTr("Import key from file")
    }

    Label {
        id: keyExistsText
        anchors { top: header.bottom; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
        visible: false
        width: parent.width
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.secondaryColor
        text: qsTr("Selected key exists already. Cannot add key.")
    }

    SilicaListView {
        id: keyFileListView
        anchors { top: keyExistsText.bottom; left: parent.left;
            right: parent.right; bottom: parent.bottom; }
        width: parent.width
        height: parent.height
        spacing: Theme.paddingMedium
        clip: true

        model: ListModel {
            id: keyListModel
        }

        delegate: ListItem {
            id: item
            width: ListView.view.width
            contentHeight: Theme.itemSizeExtraLarge
            Image {
                id: fileIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.paddingMedium
                width: Theme.iconSizeMedium
                height: Theme.iconSizeMedium
                source: "image://theme/icon-s-secure"
            }
            Label {
                id: filenameLabel
                anchors.left: fileIcon.right
                text: model.filename
            }
            Text {
                id: descriptionText
                anchors { left: fileIcon.right; top: filenameLabel.bottom; }
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                text: model.description
            }
            Label {
                id: hashLabel
                anchors { left: fileIcon.right; top: descriptionText.bottom; }
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: model.hash
            }

            ListView.onCurrentItemChanged: {
                highlighted = ListView.isCurrentItem;
                _canAcceptSelection(index);
            }

            onClicked: {
                keyFileListView.currentIndex = index;
            }

        }

        section.property: "location"
        section.criteria: ViewSection.FullString
        section.delegate: Component {
            Rectangle {
                width: childrenRect.width
                height: childrenRect.height
                anchors.bottomMargin: Theme.paddingLarge
                color: "transparent"
                Image {
                    id: sectionIcon
                    anchors.margins: Theme.paddingMedium                    
                    source: "image://theme/" + (section === "documents" ? "icon-m-document" : "icon-m-device-download")
                }
                Label {
                    anchors.left: sectionIcon.right
                    anchors.verticalCenter: sectionIcon.verticalCenter
                    font.family: Theme.fontFamilyHeading
                    color: Theme.highlightColor
                    text: section === "documents" ? qsTr("Documents") : qsTr("Downloads")
                }
            }
        }

        VerticalScrollDecorator {}
    }

    onAccepted: _create(keyListModel.get(keyFileListView.currentIndex).path)
}
