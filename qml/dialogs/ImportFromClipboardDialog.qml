import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    Column {
        width: parent.width

        DialogHeader { }

        TextField {
            id: keyDataField
            width: parent.width
            placeholderText: qsTr("Key data of 16, 24 or 32 bytes")
            label: qsTr("Key data")
            labelVisible: true
            inputMethodHints: Qt.ImhNoPredictiveTex | Qt.ImhNoAutoUppercase
            font.capitalization: Font.SmallCaps
            validator: RegExpValidator { regExp: /(0[xX])?([0-9a-fA-F]{16}$)|([0-9a-fA-F]{24}$)||([0-9a-fA-F]{32}$)/ }
        }
        TextField {
            id: keyInitVectorField
            width: parent.width
            placeholderText: qsTr("Key initialization vector of 16 bytes")
            label: qsTr("Key initialization vector")
            labelVisible: true
            inputMethodHints: Qt.ImhNoPredictiveTex | Qt.ImhNoAutoUppercase
            font.capitalization: Font.SmallCaps
            validator: RegExpValidator { regExp: /(0[xX])?[0-9a-fA-F]{16}$/ }
        }
    }

    canAccept: keyDataField.text !== ""
}
