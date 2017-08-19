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

    property var elfCloudMock: JsMock.API.mock("elfCloud", elfCloud)
    property var keyHandlerMock: JsMock.API.mock("keyHandler", keyHandler)
    property var stateCbMock: JsMock.API.mock("stateCb")

    function test_GivenConnectionFailures_WhenBackup_ThenFinalStateIsFailed() {

        var elfCloudMock, keyHandlerMock, stateCbMock;

        JsMock.API.watch(function() {
            elfCloudMock = JsMock.API.mock("elfCloud", elfCloud);
            keyHandlerMock = JsMock.API.mock("keyHandler", keyHandler);
            stateCbMock = JsMock.API.mock("stateCb");
        });

        stateCbMock.exactly(3);
        stateCbMock.onCall(1).with("init");
        stateCbMock.onCall(2).with("fetch");
        stateCbMock.onCall(3).with("failed");
        elfCloudMock.getProperty.once().will(function(name, successCb, failureCb) { failureCb("mock reason id","mock reason message"); })

        try {
            KeyBackup.BackupKeyringToCloud(elfCloudMock, keyHandlerMock, stateCbMock, passwd);
            JsMock.API.assertWatched();
        } catch (err) {
            fail("%1 %2".arg(err.message).arg(err.stack));
        }
    }

}
