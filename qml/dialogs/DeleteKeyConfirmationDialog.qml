import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property string name
    property string hash

    Column {
        width: parent.width

        DialogHeader {
            id: header
            title: qsTr("Remove %1").arg(name)
        }

        Text
        {
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            horizontalAlignment: Text.AlignHCenter
            color: Theme.primaryColor
            text: qsTr("Key '%1' hash '%2' will be removed PERMANENTLY!").arg(name).arg(hash) + "\n\n" +
                  qsTr("If you loose a key and there is files encrypted with it, you cannot access to those files EVER AGAIN! Are you sure?")
        }
    }
}
