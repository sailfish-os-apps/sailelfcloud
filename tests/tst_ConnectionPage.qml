import QtQuick 2.0
import QtTest 1.0
import Sailfish.Silica 1.0

//import "../src/qml/pages"
import "../harbour-sailelfcloud/qml/pages"

ApplicationWindow {
    id: wholeApp

    property bool _autoLoginCleared: false

    property var elfCloud: ElfCloudAdapterMock {
        onTst_connect: { failureCb(); }
    }

    property var helpers: HelpersMock {
        function clearAutoLogin() {
            _autoLoginCleared = true;
        }
    }

    property var pageStack: Item {
        function push() {
            console.log("pushMock")
        }

        function replace() {
            console.log("replaceMock")
        }
    }

    initialPage: ConnectionPage {
        id: connectionPage
        username: "name"
        password: "passwd"
    }

    TestCase {
        name: "test "

        when: windowShown

        function test_LoginFailure_ShouldClearAutologin() {
            verify(_autoLoginCleared);
        }
    }

}


