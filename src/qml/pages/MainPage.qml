import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: mainPage

    property bool autologinDisabled: false; // allows overriding autologin from settings

    function _connect() {
        if (!helpers.isFirstTimeDone())
            pageStack.push(Qt.resolvedUrl("../dialogs/FirstTimeDialog.qml"));
        else if (helpers.isAutoLoginAllowed() && !autologinDisabled) {
            pageStack.push(Qt.resolvedUrl("ConnectionPage.qml"));
        } else {
            autologinDisabled = false;
            pageStack.replace(Qt.resolvedUrl("LoginPage.qml"));
        }
    }

    function _elfCloudReady() {
        if (keyHandler.ready)
            _connect()
    }

    function _keyHandlerReady() {
        if (elfCloud.ready)
            _connect()
    }

    Component.onCompleted: {
        if (!elfCloud.ready)
            elfCloud.readyForUse.connect(_elfCloudReady);
        if (!keyHandler.ready)
            keyHandler.readyForUse.connect(_keyHandlerReady);
    }

    onStatusChanged: {
        if (status == PageStatus.Active && elfCloud.ready && keyHandler.ready) {
            _connect();
        }
    }
}
