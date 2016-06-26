import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    signal createdKey(string hash)

    function _create(name, description, key, iv, hash) {
        keyHandler.storeKey(name, description, key, iv, hash);
        createdKey(hash);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width

            DialogHeader { }

            Text {
                width: parent.width
                anchors { left: parent.left; right: parent.right;
                          leftMargin: Theme.horizontalPageMargin;
                          rightMargin: Theme.horizontalPageMargin }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignLeft
                textFormat: Text.RichText
                font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
                color: Theme.secondaryColor
                text: qsTr("Type or copy-paste key and initialization vector in hex string format.")
            }

            TextField {
                id: keyDataField
                width: parent.width
                placeholderText: qsTr("Key data of 16, 24 or 32 bytes (in hex)")
                label: qsTr("Key data")
                labelVisible: true
                inputMethodHints: Qt.ImhNoPredictiveText
                font { capitalization: Font.AllLowercase; pixelSize: Theme.fontSizeTiny; }
                validator: RegExpValidator { regExp: /([0-9a-fA-F]{32}$)|([0-9a-fA-F]{48}$)|([0-9a-fA-F]{64}$)/ }

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
                inputMethodHints: Qt.ImhNoPredictiveText
                font { capitalization: Font.AllLowercase; pixelSize: Theme.fontSizeTiny; }
                validator: RegExpValidator { regExp: /(0[xX])?[0-9a-fA-F]{32}$/ }

                // Only allow Enter key to be pressed when valid text has been entered
                EnterKey.enabled: acceptableInput

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: keyNameField.focus = true
            }

            TextField {
                id:keyHashField
                width: parent.width
                label: qsTr("Key and initialization vector hash")
                labelVisible: true
                readOnly: true
            }

            Item {
                width: 1
                height: Theme.fontSizeLarge
            }

            TextField {
                id:keyNameField
                width: parent.width
                label: qsTr("Name")
                labelVisible: true
                placeholderText: qsTr("Key must have name")

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: keyDescriptionArea.focus = true
            }

            TextArea {
                id:keyDescriptionArea
                width: parent.width
                label: qsTr("Description")
                labelVisible: true
                placeholderText: label
                wrapMode: TextEdit.Wrap
            }

            Text
            {
                width: parent.width
                anchors { left: parent.left; right: parent.right;
                          leftMargin: Theme.horizontalPageMargin;
                          rightMargin: Theme.horizontalPageMargin }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignLeft
                textFormat: Text.RichText
                font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
                color: Theme.secondaryColor
                text: "<style>a:link { color: " + Theme.highlightColor + "; }</style>" +
                    qsTr("For more information, see:") +
                    "<br/> <a href=\"https://github.com/TeemuAhola/sailelfcloud/wiki/SailElfCloud-encryption\">" +
                    qsTr("SailElfCloud encryption") + "</a>";
                onLinkActivated:
                {
                    Qt.openUrlExternally(link);
                }
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
    }
    canAccept: keyDataField.acceptableInput && keyInitVectorField.acceptableInput && keyNameField.text
    onAccepted: _create(keyNameField.text, keyDescriptionArea.text, keyDataField.text, keyInitVectorField.text, keyHashField.text)
}
