import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: mainPage

    property bool autologinDisabled: false; // allows overriding autologin from settings
    property string keyringpassword

    function _connect() {
        if (!helpers.isFirstTimeDone()) {
            var d = pageStack.push(Qt.resolvedUrl("../dialogs/FirstTimeDialog.qml"));
            d.accepted.connect(function() { keyringpassword = d.keyringPassword; });
        }
        else if (helpers.isAutoLoginAllowed() && !autologinDisabled) {
            pageStack.push(Qt.resolvedUrl("ConnectionPage.qml"));
        } else {
            autologinDisabled = false;
            pageStack.replace(Qt.resolvedUrl("LoginPage.qml"), {'keyringpassword': keyringpassword});
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            _connect();
        }
    }
}
