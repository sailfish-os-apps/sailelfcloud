import QtQuick 2.0
import QtTest 1.0
import Sailfish.Silica 1.0

//import "../src/qml/pages"
import "../harbour-sailelfcloud/qml/pages"
import "../harbour-sailelfcloud/qml"

ApplicationWindow {

    id: root

    property var elfCloud: ElfCloudAdapter { }
    property var helpers: null

    function _createContainerPage() {
        var c = Qt.createComponent(Qt.resolvedUrl("../harbour-sailelfcloud/qml/pages/ContainerPage.qml"),
                                   Component.PreferSynchronous)
        var o = c.createObject(root);

        return o;
    }

    TestCase {
        id: testContainerPage
        name: "Test Container Page"
        when: windowShown

        signal readyToRun()

        SignalSpy {
            id: spyConnection
            target: testContainerPage
            signalName: "readyToRun"
        }

        function initTestCase() {
            elfCloud.connect("username", "passwd", readyToRun);
            spyConnection.wait(5000);
            compare(1, spyConnection.count, "Connection timed out");
        }

        function cleanupTestCase() {
            elfCloud.disconnect();
        }

        SignalSpy {
            id: spyContainerPage
        }

        function test_OpenContainerPage_ShouldListVaults() {
            var page = _createContainerPage();
            spyContainerPage.target = page;
            spyContainerPage.signalName = "_added";
            pageStack.push(page);
            spyContainerPage.wait(5000);
            compare(1, spyContainerPage.count, "Failed to list vaults");
        }
    }
}
