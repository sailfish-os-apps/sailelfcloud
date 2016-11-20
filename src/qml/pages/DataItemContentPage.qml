import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    allowedOrientations: Orientation.All

    property string dataItemName
    property int parentContainerId
    property var key: undefined
    property var iv: undefined

    function _displayUnknownFile(path, mime) {
        busyIndication.running = false;
        unknownFileMimeArea.text = qsTr("File mime type '%1' is not supported by this view. Using external application.").arg(mime);
        unknownFileMimeArea.visible = true;
        Qt.openUrlExternally(path);
    }

    function _updateTextViewForPlainFile(text, mime) {
        fileContentLabel.text = text;
        fileContentLabel.font.pixelSize = Theme.fontSizeMedium
        fileContentLabel.color = Theme.highlightColor
        mimeLabel.text = mime;
        busyIndication.running = false;
        flickableForText.visible = true;
    }

    function _displayPlainFile(filename, mime) {
        _updateTextViewForPlainFile(helpers.readPlainFile(filename), mime);
    }

    function _displayFile(parentId, name, localPath) {
        var mime = helpers.getFileMimeType(localPath);
        console.debug("File:", localPath, "mime type is", mime);

        if (mime === "text/plain")
            _displayPlainFile(localPath, mime);
        else
            _displayUnknownFile(localPath, mime);
    }

    function _handleFetchDataItemCompleted(parentId, remoteName, localName) {
        if (parentId === parentContainerId && remoteName === dataItemName)
        {
            _displayFile(parentId, remoteName, localName);
        }
    }

    function _fetchDataItem() {
        var outputPath = helpers.generateLocalPathForRemoteDataItem(parentContainerId, dataItemName);
        console.debug("Fetching", dataItemName, "from", parentContainerId, "to", outputPath);

        if (key !== undefined && iv !== undefined)
            elfCloud.setEncryptionKey(key, iv);
        else
            elfCloud.clearEncryption();

        elfCloud.fetchDataItem(parentContainerId, dataItemName, outputPath);
    }

    Component.onCompleted: {
        elfCloud.fetchDataItemCompleted.connect(_handleFetchDataItemCompleted);
        _fetchDataItem();
    }

    Component.onDestruction: {
        elfCloud.fetchDataItemCompleted.disconnect(_handleFetchDataItemCompleted);
    }

    BusyIndicator {
        id: busyIndication
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: true
    }

    TextArea {
        id: unknownFileMimeArea
        anchors.fill: parent
        verticalAlignment: TextEdit.AlignVCenter
        horizontalAlignment: TextEdit.AlignHCenter
        textMargin: width / 8
        labelVisible: false
        readOnly: true
        wrapMode: TextEdit.Wrap
        visible: false
    }

    SilicaFlickable {
        id: flickableForText
        visible: false
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator { flickable: flickableForText }

        Column {
            id: column
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            PageHeader { title: dataItemName }

            Label {
                id: mimeLabel
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                font.family: "Monospace"
                color: Theme.secondaryColor
            }
            Item {
                width: parent.width
                height: 2*Theme.paddingLarge
            }
            Label {
                id: fileContentLabel
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignLeft
            }
            Item {
                width: parent.width
                height: 2*Theme.paddingLarge
            }
        }
        HorizontalScrollDecorator { flickable: flickableForText }
    }
}


