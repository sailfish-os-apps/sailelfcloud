import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: mainPage

    property bool autologinDisabled: false; // allows overriding autologin from settings

    function _connect() {
        if (helpers.isAutoLoginAllowed() && !autologinDisabled) {
            var username = helpers.getSettingsUserName();
            var password = helpers.getSettingsPassword();
            pageStack.push(Qt.resolvedUrl("ConnectionPage.qml"),
                           {"username":username,"password":password});
        } else {
            autologinDisabled = false;
            pageStack.replace(Qt.resolvedUrl("LoginPage.qml"));
        }
    }

    Component.onCompleted: {
        if (!elfCloud.ready)
            elfCloud.readyForUse.connect(_connect);
    }

    onStatusChanged: {
        if (status == PageStatus.Active && elfCloud.ready) {
            _connect();
        }
    }
}
