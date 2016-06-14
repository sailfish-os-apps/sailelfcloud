import QtQuick 2.0
import Sailfish.Silica 1.0

Page
{
    property int id
    property string message

    id: page

    function _getGuidelineTranslationForId(id) {
        switch(id) {
        case 204:
            return "<style>a:link { color: " + Theme.highlightColor + "; }</style><br/>" +
                   qsTr("You must logon to the My elfCLOUD web application and accept EULA in order to use this service.") +
                   "<br/><br/>" +
                   "<a href=\"https://secure.elfcloud.fi/en_US/\">" + qsTr("https://secure.elfcloud.fi/en_US/") + "</a>";
        default:
            return ""
        }
    }

    Column
    {
        id: column

        spacing: 5
        width: parent.width

        Item
        {
            width: 1
            height: Theme.fontSizeExtraLarge
        }
        Label
        {
            anchors { horizontalCenter: parent.horizontalCenter }
            color: Theme.secondaryHighlightColor
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeExtraLarge }
            text: qsTr("Problem occurred")
        }
        Label
        {
            anchors { horizontalCenter: parent.horizontalCenter }
            color: Theme.primaryColor
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeMedium }
            text: id
        }
        Text
        {
            anchors { horizontalCenter: parent.horizontalCenter }
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
            color: Theme.secondaryColor
            text: message
        }
        Text
        {
            id: extraGuidelines
            anchors { horizontalCenter: parent.horizontalCenter }
            width: parent.width - parent.width / 5
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.RichText
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
            color: Theme.secondaryHighlightColor
            text: _getGuidelineTranslationForId(id)

            onLinkActivated:
            {
                Qt.openUrlExternally(link);
            }
        }
    }
}
