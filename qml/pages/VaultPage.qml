import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"
import ".."

Page {
    id: page

    Component.onCompleted: {
        page.actBusy();
        page.refresh();
    }

    function refresh() {
        elfCloud.listVaults(function(vaultList) {
            listModel.clear();
            listModel.addVaults(vaultList)
            page.makeVisible();
        });
    }

    function makeVisible() {
        busyIndication.running = false
        listView.visible = true

        if (listView.count == 0) {
            noContentIndication.enabled = true;
        }
    }

    function actBusy() {
        busyIndication.running = true
        listView.visible = false
    }

    BusyIndicator {
        id: busyIndication
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: true
    }

    SilicaListView {
        id: listView

        header: PageHeader {
            title: qsTr("Vaults")
        }

        CommonPullDownMenu {
            id: pulldown

            MenuItem {
                text: qsTr("Add vault")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/AddVaultDialog.qml"));
                    dialog.onCreateVault.connect( function(name) {
                        console.info("Creating vault", name);
                        elfCloud.addVault(name, function() { page.refresh(); });
                    });
                }
            }
        }

        model: ListModel { id: listModel
            function addVaults(vaultList) {
                for (var i = 0; i < vaultList.length; i++) {
                    console.log("Vault: " + vaultList[i].contentName + ", id: " + vaultList[i].contentId);
                    append({"vault":vaultList[i]});
                }
            }
        }
        anchors.fill: parent
        visible: false

        delegate: BackgroundItem {
            id: itemVaults
            width: parent.width

            Image {
                id: listIcon
                x: Theme.paddingLarge
                y: Theme.paddingMedium
                source: "image://theme/icon-m-folder"
            }

            Label {
                id: labelVaultName
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                text: model.vault.contentName
                color: itemVaults.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: vaultInfo
                anchors.top: labelVaultName.bottom
                anchors.left: listIcon.right
                anchors.leftMargin: Theme.paddingMedium
                text: qsTr("owner: ") + model.vault.contentOwnerFirstName + " " + model.vault.contentOwnerLastName
                font.pixelSize: Theme.fontSizeSmall
                color: itemVaults.highlighted ? Theme.highlightColor : Theme.secondaryColor
            }

            onClicked: {
                console.log("Opening vault " + model.vault.contentId);
                pageStack.push(Qt.resolvedUrl("ContentPage.qml"),
                               {"details"   : model.vault,
                                "parentName": qsTr("Vaults")});
            }
        }

        ViewPlaceholder {
            id: noContentIndication
            enabled: false
            text: "No content"
        }

        VerticalScrollDecorator {}
    }
}





