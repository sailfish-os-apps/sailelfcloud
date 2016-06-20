import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    Column {
        width: parent.width

        DialogHeader { }

        TextArea {
            width: parent.width
            readOnly: true
            wrapMode: TextEdit.Wrap
            font.pixelSize: Theme.fontSizeSmall
            text: qsTr("Type or copy-paste key and initialization vector in hex string format. For more details, see <link>")
        }

        TextField {
            id: keyDataField
            width: parent.width
            placeholderText: qsTr("Key data of 16, 24 or 32 bytes (in hex)")
            label: qsTr("Key data")
            labelVisible: true
            inputMethodHints: Qt.ImhNoPredictiveTex | Qt.ImhNoAutoUppercase
            font { capitalization: Font.AllLowercase; pixelSize: Theme.fontSizeTiny; }
            validator: RegExpValidator { regExp: /([0-9a-fA-F]{32}$)|([0-9a-fA-F]{48}$)||([0-9a-fA-F]{64}$)/ }
            text: "dcf4c682c503065c134d38339309159f"

            // Only allow Enter key to be pressed when valid text has been entered
            EnterKey.enabled: acceptableInput

            // Show 'next' icon to indicate pressing Enter will move the
            // keyboard focus to the next text field in the page
            EnterKey.iconSource: "image://theme/icon-m-enter-next"

            // When Enter key is pressed, move the keyboard focus to the
            // next field
            EnterKey.onClicked: keyInitVectorField.focus = true

        }
        TextField {
            id: keyInitVectorField
            width: parent.width
            placeholderText: qsTr("Initialization vector of 16 bytes (in hex)")
            label: qsTr("Initialization vector")
            labelVisible: true
            inputMethodHints: Qt.ImhNoPredictiveTex | Qt.ImhNoAutoUppercase
            font { capitalization: Font.AllLowercase; pixelSize: Theme.fontSizeTiny; }
            validator: RegExpValidator { regExp: /(0[xX])?[0-9a-fA-F]{32}$/ }
            text: "4d3aba11ff0300bb4c6210a3b07f8d57"

            // Only allow Enter key to be pressed when valid text has been entered
            EnterKey.enabled: acceptableInput

            // Close the on-screen keyboard when enter is clicked
            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            EnterKey.onClicked: focus = false
        }

        Item {
            height: Theme.paddingMedium
        }

        TextField {
            id:keyHashField
            width: parent.width
            label: qsTr("Key and initialization vector hash")
            labelVisible: true
            readOnly: true
        }
    }

    Connections {
        target: keyDataField
        onAcceptableInputChanged: {
            if (keyDataField.acceptableInput && keyInitVectorField.acceptableInput) {
                keyHashField.text = helpers.hashDataBeaverMd5Hex(keyInitVectorField.text+keyDataField.text)
            } else
                keyHashField.text = ""
        }
    }

    Connections {
        target: keyInitVectorField
        onAcceptableInputChanged: {
            if (keyDataField.acceptableInput && keyInitVectorField.acceptableInput)
                keyHashField.text = helpers.hashDataBeaverMd5Hex(keyInitVectorField.text+keyDataField.text)
            else
                keyHashField.text = ""
        }
    }

    canAccept: keyDataField.acceptableInput && keyInitVectorField.acceptableInput
}
