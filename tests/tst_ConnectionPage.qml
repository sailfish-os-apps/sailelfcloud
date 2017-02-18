import QtQuick 2.0
import QtTest 1.0
import Sailfish.Silica 1.0

//import "../src/qml/pages"
import "../harbour-sailelfcloud/qml/pages"

ApplicationWindow {

    id: root

    property var pageStack: null
    property var elfCloud: null
    property var helpers: null

    function _createConnectionPage() {
        var c = Qt.createComponent("../harbour-sailelfcloud/qml/pages/ConnectionPage.qml",
                                   Component.PreferSynchronous)
        return c.createObject(null, {"username":"name","password":"passwd"});
    }

    TestCase {
        id: failedConnectionTest
        name: "Failed connection"
        when: windowShown

        property bool autoLoginCleared: false

        property var elfCloudMock: ElfCloudAdapterMock {
            onTst_connect: { failureCb(); }
        }

        property var helpersMock: HelpersMock {
            function clearAutoLogin() {
                failedConnectionTest.autoLoginCleared = true;
            }
        }

        function test_LoginFailureGiven_WhenPageActivates_ShouldClearAutologin() {
            root.elfCloud = elfCloudMock;
            root.helpers = helpersMock;
            _createConnectionPage().status = PageStatus.Active;
            verify(autoLoginCleared);
        }
    }

    TestCase {
        name: "Succesfull connection"

        when: windowShown

        property var elfCloudMock: ElfCloudAdapterMock {
            onTst_connect: { successCb(); }
        }

        property var pageStackMock: Item {
            function push() {
                console.log("pushMock");
            }

            function replace() {
                console.log("replaceMock");
            }

            function replaceAbove() {
                console.log("replaceAboveMock");

            }
        }

        function test_LoginSuccessGiven_WhenPageActivates_ShouldMoveToContainerPage() {
            root.elfCloud = elfCloudMock;
            root.pageStack = pageStackMock;
            _createConnectionPage().status = PageStatus.Active;
        }
    }

}


