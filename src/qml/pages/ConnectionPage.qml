import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {

    readonly property string username: helpers.getSettingsUserName()
    readonly property string password: helpers.getSettingsPassword()
    readonly property string keyringpassword: helpers.getSettingsKeyringPassword()

    id: page

    property bool _triedConnect: false

    function _keychainInitCb() {
        busyIndication.running = false;
        pageStack.replaceAbove(null, Qt.resolvedUrl("ContainerPage.qml"));
    }

    function _connectionSucceededCb() {
        _triedConnect = true;
        keyHandler.secureInit(keyringpassword, _keychainInitCb);
    }

    function _connectionFailedCb() {
        busyIndication.running = false;
        _triedConnect = true;
        helpers.clearAutoLogin();
    }

    onStatusChanged: {
        if (status === PageStatus.Active && !_triedConnect) {
            elfCloud.connect(username, password, _connectionSucceededCb, _connectionFailedCb);
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

