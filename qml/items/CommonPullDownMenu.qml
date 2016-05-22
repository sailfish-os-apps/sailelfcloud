import QtQuick 2.0
import Sailfish.Silica 1.0

// PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
PullDownMenu {

    MenuItem {
        text: qsTr("Disconnect")
        onClicked: elfCloud.disconnect(function(status) {
            console.log("Disconnected");
            pageStack.replaceAbove(null, Qt.resolvedUrl("../pages/MainPage.qml"), {"autologinDisabled": true});
        });
    }
    MenuItem {
        text: qsTr("Configuration")
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/ConfigPage.qml"));
    }
}

