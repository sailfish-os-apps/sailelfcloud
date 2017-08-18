import QtQuick 2.0
import QtTest 1.0
import Sailfish.Silica 1.0

//import "../src/qml/pages"
import "../harbour-sailelfcloud/qml/pages"
import "../harbour-sailelfcloud/qml/helpers/keyBackup.js" as KeyBackup

ApplicationWindow {

    id: root

    property var elfCloud: null
    property var keyHandler: null

    function _createPage() {
        var c = Qt.createComponent(Qt.resolvedUrl("../harbour-sailelfcloud/qml/pages/KeychainBackupPage.qml"),
                                   Component.PreferSynchronous)
        return c.createObject();
    }

    TestCase {
        name: "Version check failures"
        when: windowShown

        property var elfCloudMock: QtObject {

            readonly property string unsupportedKeyBackupVersion: "2.0"

            function setProperty(name, data, successCb, failureCb) {
            }

            function getProperty(name, successCb, failureCb) {
                if (KeyBackup.CLOUD_KEYRING_ACTIVE === name)
                    successCb(KeyBackup.CLOUD_KEYRING_1);
                else if (KeyBackup.CLOUD_KEYRING_1 === name) {
                    var jsonObject = {
                        "version": unsupportedKeyBackupVersion,
                        "timestamp": "",
                        "keyring": ""
                    }
                    successCb(JSON.stringify(jsonObject));
                }
            }
        }

        property var keyHandlerMock: QtObject {
        }

        function test_GivenUnsupportedVersionInCould_WhenPageCreated_ThenGoesToFailedState() {
            root.elfCloud = elfCloudMock;
            root.keyHandler = keyHandlerMock;
            var page = _createPage();
            pageStack.push(page);
            compare(page.state, "failed");
        }
    }

    TestCase {
        id: test_succesfulBackup
        name: "Succesful backup"
        when: windowShown

        readonly property var testKeys: [
            {
                description: "description",
                type: "type",
                mode: "mode",
                iv: "iv",
                key: "key",
                hash: "hash"
            }
        ]

        property var elfCloudMock: QtObject {

            property var storedKeyringBackup: undefined
            property var activeKeyring: undefined

            function setProperty(name, data, successCb, failureCb) {

                if (KeyBackup.CLOUD_KEYRING_2 === name)
                    storedKeyringBackup = data;
                else if (KeyBackup.CLOUD_KEYRING_ACTIVE === name)
                    activeKeyring = data;

                successCb();
            }

            function getProperty(name, successCb, failureCb) {

                if (KeyBackup.CLOUD_KEYRING_ACTIVE === name)
                    successCb(undefined);
                else if (KeyBackup.CLOUD_KEYRING_1 === name && ! storedKeyringBackup)
                    successCb(undefined);
                else if (KeyBackup.CLOUD_KEYRING_2 === name && storedKeyringBackup)
                    successCb(storedKeyringBackup);
            }
        }

        property var keyHandlerMock: QtObject {
            function getKeys() {
                return test_succesfulBackup.testKeys;
            }
        }

        function test_GivenNoIssuesOccurs_WhenPageCreated_ThenGoesToDoneState() {
            root.elfCloud = elfCloudMock;
            root.keyHandler = keyHandlerMock;
            var page = _createPage();
            compare(page.state, "done");
        }
    }


}
