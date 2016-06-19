import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    function _createKey(index) {
        switch (index) {
        case 2:
            var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/ImportFromClipboardDialog.qml"));
            break;
        }
    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        PullDownMenu {

        }

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column
            width: page.width
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Encryption configurations")
            }

            SectionHeader {
                text: qsTr("Encryption key creation")
            }
            Row {
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
                text: qsTr("Available encryption keys")
            }
        }
    }
}


