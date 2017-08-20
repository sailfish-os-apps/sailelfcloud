import QtQuick 2.0
import QtTest 1.0

import "../harbour-sailelfcloud/qml/helpers/keyBackup.js" as KeyBackup
import "js-mock.js" as JsMock

TestCase {
    name: "KeyBackup tests"

    readonly property string passwd: "password"

    property var elfCloud: QtObject {
        function setProperty(name, data, successCb, failureCb) {}
        function getProperty(name, successCb, failureCb) {}
    }

    property var keyHandler: QtObject {
        function getKeys() {}
    }

    function test_GivenConnectionFailures_WhenBackup_ThenFinalStateIsFailed() {

        var elfCloudMock, keyHandlerMock, stateCbMock;

        JsMock.JsMock.watch(function() {
            elfCloudMock = JsMock.JsMock.mock("elfCloud", elfCloud);
            keyHandlerMock = JsMock.JsMock.mock("keyHandler", keyHandler);
            stateCbMock = JsMock.JsMock.mock("stateCb");
        });

        stateCbMock.exactly(3);
        stateCbMock.onCall(1).with("init");
        stateCbMock.onCall(2).with("fetch");
        stateCbMock.onCall(3).with("failed");
        elfCloudMock.getProperty.once().will(function(name, successCb, failureCb) { failureCb("mock reason id","mock reason message"); })

        try {
            KeyBackup.BackupKeyringToCloud(elfCloudMock, keyHandlerMock, stateCbMock, passwd);
            JsMock.JsMock.assertWatched();
        } catch (err) {
            fail("%1 %2".arg(err.message).arg(err.stack));
        }
    }

}
