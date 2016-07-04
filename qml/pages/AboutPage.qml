import QtQuick 2.0
import Sailfish.Silica 1.0

Page
{
    id: page

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
        Image
        {
            anchors { horizontalCenter: parent.horizontalCenter }
            source: "../icons/sailelfcloud.png"
        }
        Label
        {
            id: titleLabel
            text: qsTr("SailElfCloud")
            anchors { horizontalCenter: parent.horizontalCenter }
            color: Theme.highlightColor
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeExtraLarge * 1.5 }
        }
        Label
        {
            text: qsTr("Version %1").arg("2.0")
            anchors { horizontalCenter: titleLabel.horizontalCenter }
            color: Theme.secondaryHighlightColor
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeExtraLarge }
        }
        Label
        {
            text: qsTr("Copyright © 2016 Teemu Ahola")
            anchors { horizontalCenter: titleLabel.horizontalCenter }
            color: Theme.primaryColor
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeMedium }
        }
        Text
        {
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.RichText
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
            color: Theme.secondaryColor
            text: "<style>a:link { color: " + Theme.highlightColor + "; }</style><br/>" +
                qsTr("This program is open source software licensed under the terms of the GNU General Public License.") +
                "<br/><br/>" + qsTr("You can find the source code at the") +
                "<br/> <a href=\"https://github.com/TeemuAhola/sailelfcloud\">" + qsTr("GitHub Project Page") + "</a>";
            onLinkActivated:
            {
                Qt.openUrlExternally(link);
            }
        }
    }
    Text
    {
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        horizontalAlignment: Text.AlignHCenter
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.paddingSmall }
        color: Theme.secondaryHighlightColor
        font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
        text: qsTr("Uses software from elfGROUP (https://secure.elfcloud.fi/en_US/)")
    }
}
