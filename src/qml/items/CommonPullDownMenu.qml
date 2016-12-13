import QtQuick 2.0
import Sailfish.Silica 1.0

// PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
PullDownMenu {

    property bool transfersVisible: true

    MenuItem {
        text: qsTr("Configuration")
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/ConfigPage.qml"));
    }
    MenuItem {
        text: qsTr("Transfers")
        visible: transfersVisible
        onClicked: pageStack.push(Qt.resolvedUrl("../pages/TransfersPage.qml"));
    }
}

