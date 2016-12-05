import QtQuick 2.0
import Sailfish.Silica 1.0

// PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
PullDownMenu {
    MenuItem {
        text: qsTr("Configuration")
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/ConfigPage.qml"));
    }
    MenuItem {
        text: qsTr("Transfers")
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/TransfersPage.qml"));
    }
}

