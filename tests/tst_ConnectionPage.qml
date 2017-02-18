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

    readonly property string username: "name"
    readonly property string password: "passwd"

    function _createConnectionPage() {
        var c = Qt.createComponent(Qt.resolvedUrl("../harbour-sailelfcloud/qml/pages/ConnectionPage.qml"),
                                   Component.PreferSynchronous)
        return c.createObject(null, {"username":username,"password":password});
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
        id: succeedConnectionTest
        name: "Succesfull connection"

        when: windowShown

        property var elfCloudMock: ElfCloudAdapterMock {
            onTst_connect: {
                succeedConnectionTest.verify(username);
                succeedConnectionTest.verify(password);
                successCb();
            }
        }

        property var pageStackMock: Item {
            function replaceAbove(existingPage, newPage) {
                succeedConnectionTest.verify(newPage === Qt.resolvedUrl("../harbour-sailelfcloud/qml/pages/ContainerPage.qml"));
            }
        }

        function test_LoginSuccessGiven_WhenPageActivates_ShouldLoginUsingValidCreditialsAndMoveToContainerPage() {
            root.elfCloud = elfCloudMock;
            root.pageStack = pageStackMock;
            _createConnectionPage().status = PageStatus.Active;
        }
    }

}


