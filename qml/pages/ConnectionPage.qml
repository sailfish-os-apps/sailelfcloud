import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {

    property string username;
    property string password;

    id: page

    function _connectionCb(status) {
        busyIndication.running = false;
        if (status) {
            pageStack.replaceAbove(null, Qt.resolvedUrl("VaultPage.qml"));
        } else {
            connectionProblemLabel.text = qsTr("Failed to connect");
            connectionProblemLabel.visible = true;
            helpers.clearAutoLogin();
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            elfCloud.connect(username, password, _connectionCb);
        }
    }

    PageHeader {
        title: qsTr("Connecting")
    }

    BusyIndicator {
        id: busyIndication
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: true
    }

    Label {
        id: connectionProblemLabel
        anchors.centerIn: parent
        visible: false
    }
}

