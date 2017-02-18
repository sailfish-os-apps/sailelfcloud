import QtQuick 2.0
import QtTest 1.0
import Sailfish.Silica 1.0

//import "../src/qml/pages"
import "../harbour-sailelfcloud/qml/pages"

ApplicationWindow {

    id: root

    property var elfCloud: null
    property var helpers: null

    function _createTransfersPage() {
        var c = Qt.createComponent(Qt.resolvedUrl("../harbour-sailelfcloud/qml/pages/TransfersPage.qml"),
                                   Component.PreferSynchronous)
        return c.createObject();
    }

    TestCase {
        id: testX
        name: "Test X"
        when: windowShown

        readonly property var stores: [{"uid":11,
                                        "remoteName":"remote name 1",
                                        "parentId":9998,
                                        "totalSize":1000,
                                        "state":"ongoing"}]

        readonly property var stores2: []

        readonly property var fetches: [{"uid":12,
                                         "remoteName":"remote name 2",
                                         "parentId":9999,
                                         "totalSize":1000,
                                         "state":"ongoing"}]

        property var elfCloudMock: ElfCloudAdapterMock {
            onTst_listStores: { callback(testX.stores); }
            onTst_listFetches: { callback(testX.fetches); }
        }

        property var elfCloudMock2: ElfCloudAdapterMock {
            onTst_listStores: { callback(testX.stores2); }
            onTst_listFetches: { callback(testX.fetches); }
        }

        property var helpersMock: HelpersMock {
            function clearAutoLogin() {
                failedConnectionTest.autoLoginCleared = true;
            }
        }

        function test_xxxx() {
            root.elfCloud = elfCloudMock;
            pageStack.push(_createTransfersPage());
            wait(3000);
            root.elfCloud = elfCloudMock2;
            elfCloudMock.storeDataItemCompleted(9998, "remote name 1", "");
            wait(3000);
        }
    }


}
