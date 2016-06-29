import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {

    property string username;
    property string password;

    id: page

    property bool _triedConnect: false

    function _connectionCb(status) {
        busyIndication.running = false;
        _triedConnect = true;
        if (status) {
            pageStack.replaceAbove(null, Qt.resolvedUrl("ContainerPage.qml"));
        } else {
            helpers.clearAutoLogin();
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && !_triedConnect) {
            elfCloud.connect(username, password, _connectionCb);
        } else if (status === PageStatus.Active && _triedConnect) {
            pageStack.pop();
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

