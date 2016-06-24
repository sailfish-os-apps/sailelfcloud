import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {

    property string username;
    property string password;

    id: page

    function _connectionCb(status, reason) {
        elfCloud.onConnected.disconnect(_connectionCb);
        busyIndication.running = false;
        if (status) {
            var activeKeyHash = helpers.getActiveKey();

            if (activeKeyHash) {
                var key = keyHandler.getKey(activeKeyHash);
                elfCloud.setEncryptionKey(key["data"], key["iv"]);
            }

            pageStack.replaceAbove(null, Qt.resolvedUrl("ContainerPage.qml"));
        } else {
            connectionProblemLabel.text = qsTr("Failed to connect");
            connectionProblemLabel.visible = true;
            connectionProblemReasonArea.text = reason;
            connectionProblemReasonArea.visible = true;            
            connectionProblemSolutionArea.text =
                "<style>a:link { color: " + Theme.highlightColor + "; }</style><br/>" +
                "<br/>" + qsTr("Are you missing account? Create one in") +
                "<br/> <a href=\"https://secure.elfcloud.fi/en_US/\"> https://secure.elfcloud.fi/en_US/</a>";

            helpers.clearAutoLogin();
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            elfCloud.onConnected.connect(_connectionCb);
            elfCloud.connect(username, password);
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
        font.family: Theme.fontFamilyHeading
        visible: false
    }
    TextArea {
        id: connectionProblemReasonArea
        anchors.top: connectionProblemLabel.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        font.pixelSize: Theme.fontSizeSmall
        horizontalAlignment: TextEdit.AlignHCenter
        textMargin: parent.width / 5
        labelVisible: false
        readOnly: true
        wrapMode: TextEdit.Wrap
        visible: false
    }
    Text
    {
        id: connectionProblemSolutionArea
        width: parent.width
        anchors { top: connectionProblemReasonArea.bottom;
                  left: parent.left;
                  right: parent.right }
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.RichText
        font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
        color: Theme.secondaryColor
        onLinkActivated:
        {
            Qt.openUrlExternally(link);
        }
    }
}

