import QtQuick 2.0
import Sailfish.Silica 1.0
import "../helpers/keyRestore.js" as KeyRestore

Page {

    property string password;

    id: page
    backNavigation: false

    function _stateCb(state, reason) {
        switch (state) {
        case 'init':
            page.state = 'initial';
            break;
        case 'fetch':
            page.state = 'fetch';
            break;
        case 'merge':
            page.state = 'merge';
            break;
        case 'store':
            page.state = 'store';
            break;
        case 'verify':
            page.state = 'verify';
            break;
        case 'done':
            page.state = 'done';
            break;
        case 'failed':
            if (reason !== undefined)
                failedReason.reason = reason;
            page.state = 'failed';
            break;
        }
    }

    Component.onCompleted: {
        KeyRestore.RestoreKeyringFromCloud(elfCloud, keyHandler, _stateCb);
    }

    states: [
        State {
            name: "initial"
            PropertyChanges { target: fetchingFromCloud; visible: false; restoreEntryValues: false }
            PropertyChanges { target: mergingKeychains; visible: false; restoreEntryValues: false }
            PropertyChanges { target: storeLocally; visible: false; restoreEntryValues: false }
            PropertyChanges { target: done; visible: false; restoreEntryValues: false }
            PropertyChanges { target: failed; visible: false; restoreEntryValues: false }
            PropertyChanges { target: closeButton; visible: false; restoreEntryValues: false }
            PropertyChanges { target: busyIndication; running: true; restoreEntryValues: false }
        },
        State {
            name: "fetch"
            PropertyChanges { target: fetchingFromCloud; visible: true; restoreEntryValues: false }
        },
        State {
            name: "merge"
            PropertyChanges { target: mergingKeychains; visible: true; restoreEntryValues: false }
        },
        State {
            name: "store"
            PropertyChanges { target: storeLocally; visible: true; restoreEntryValues: false }
        },
        State {
            name: "done"
            PropertyChanges { target: done; visible: true; restoreEntryValues: false }
            PropertyChanges { target: closeButton; visible: true; restoreEntryValues: false }
            PropertyChanges { target: busyIndication; running: false; restoreEntryValues: false }
        },
        State {
            name: "failed"
            PropertyChanges { target: failed; visible: true; restoreEntryValues: false }
            PropertyChanges { target: closeButton; visible: true; restoreEntryValues: false }
            PropertyChanges { target: busyIndication; running: false; restoreEntryValues: false }
        }
    ]

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Keychain restore")
            }

            Label {
                id: fetchingFromCloud
                font.family: Theme.fontFamilyHeading
                x: Theme.horizontalPageMargin
                visible: false
                text: qsTr("Fetching from cloud")
            }

            Label {
                id: mergingKeychains
                font.family: Theme.fontFamilyHeading
                x: Theme.horizontalPageMargin
                visible: false
                text: qsTr("Merging keychains")
            }

            Label {
                id: storeLocally
                font.family: Theme.fontFamilyHeading
                x: Theme.horizontalPageMargin
                visible: false
                text: qsTr("Store to local")
            }

            Label {
                id: done
                font.family: Theme.fontFamilyHeading
                x: Theme.horizontalPageMargin
                visible: false
                text: qsTr("Done")
            }

            Label {
                id: failed
                property string reason: ""
                font.family: Theme.fontFamilyHeading
                x: Theme.horizontalPageMargin
                visible: false
                text: qsTr("Failed")
            }

            TextEdit {
                id: failedReason
                property string reason: ""
                x: Theme.horizontalPageMargin * 2
                width: parent.width - x - Theme.horizontalPageMargin
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                visible: reason !== ""
                wrapMode: TextEdit.WordWrap
                readOnly: true
                text: reason
            }

            Button {
                id: closeButton
                text: qsTr("Close")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: pageStack.pop()
                visible: false
            }

            Separator {
            }

            BusyIndicator {
                id: busyIndication
                size: BusyIndicatorSize.Medium
                anchors.horizontalCenter: parent.horizontalCenter
                running: false
            }
        }
    }
}
