import QtQuick 2.0

Item {

    property bool ready: false // True if init done succesfully

    signal readyForUse()

    signal tst_connect(string username, string password, var successCb, var failureCb)

    function connect(username, password, successCb, failureCb) {
        tst_connect(username, password, successCb, failureCb);
    }

    Component.onCompleted: {
        ready = true;
        readyForUse();
    }

}

