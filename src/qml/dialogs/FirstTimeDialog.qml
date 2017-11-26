import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    SilicaFlickable {
        anchors.fill: parent

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader { title: qsTr("First time setup") }

            Text
            {
                anchors {
                    left: parent.left;
                    right: parent.right;
                    leftMargin: Theme.horizontalPageMargin;
                    rightMargin: Theme.horizontalPageMargin
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignJustify
                color: Theme.secondaryHighlightColor
                textFormat: Text.RichText
                font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
                text: qsTr("Local keyring for encryption keys will be encrypted. " +
                           "Therefore password for encryption must be provided. " +
                           "For more info see ") +
                           "<style>a:link { color: " + Theme.highlightColor + "; }</style>" +
                           qsTr("<a href=\"https://github.com/TeemuAhola/sailelfcloud/wiki/SailElfCloud-encryption\">" + qsTr("SailfElfCloud encryption") + "</a>")
                onLinkActivated:
                {
                    Qt.openUrlExternally(link);
                }
            }

            Item
            {
                width: 1
                height: Theme.fontSizeExtraLarge
            }

            PasswordField {
                id: keyringPasswordField
                width: parent.width
                placeholderText: qsTr("Enter Password")
                label: qsTr("Keyring Password")
                showEchoModeToggle: true

                // Only allow Enter key to be pressed when text has been entered
                EnterKey.enabled: text.length > 0

                // Show 'next' icon to indicate pressing Enter will move the
                // keyboard focus to the next text field in the page
                EnterKey.iconSource: "image://theme/icon-m-enter-next"

                // When Enter key is pressed, move the keyboard focus to the
                // next field
                EnterKey.onClicked: keyringPasswordVerifyField.focus = true
            }

            PasswordField {
                id: keyringPasswordVerifyField
                width: parent.width
                placeholderText: qsTr("Enter Password again for verify")
                label: qsTr("Keyring Password")
                showEchoModeToggle: true

                // Only allow Enter key to be pressed when text has been entered
                EnterKey.enabled: text.length > 0

                // Close the on-screen keyboard when enter is clicked
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            TextSwitch {
                id: autologin
                text: qsTr("Remember keyring password")
                description: qsTr("Remember password when logging in.")
                checked: helpers.isAutoLogin()
            }
        }
    }

    onAccepted: helpers.setSettingsKeyringPassword(keyringPasswordField.text);
    canAccept: keyringPasswordField.text.length > 0 && keyringPasswordField.text === keyringPasswordVerifyField.text
}
