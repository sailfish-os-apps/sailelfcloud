import QtQuick 2.0
import Sailfish.Silica 1.0

Page
{
    Column
    {
        width: parent.width

        PageHeader {
            title: qsTr("Encrypting local keyring")
        }

        Item
        {
            width: 1
            height: Theme.fontSizeExtraLarge
        }
        Label
        {
            text: qsTr("SailElfCloud")
            anchors { horizontalCenter: parent.horizontalCenter }
        }
    }
}
