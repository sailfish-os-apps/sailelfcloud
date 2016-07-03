import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property string containerName

    Column {
        width: parent.width

        DialogHeader {
            id: header
            title: qsTr("Remove %1").arg(containerName)
        }

        Text
        {
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
            color: Theme.primaryColor
            text: qsTr("Cluster %1 and all items under it will be removed PERMANENTLY!").arg(containerName) + "\n" +
                  qsTr("Are you sure?")
        }
    }
}
