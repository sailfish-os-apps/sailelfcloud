import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height


        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Configuration")
                onClicked: pageStack.push(Qt.resolvedUrl("ConfigPage.qml"));
            }
        }

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column
            width: page.width
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Login")
            }

            TextField {
                id: usernameField
                width: parent.width
                placeholderText: qsTr("Enter Username")
                label: qsTr("Username")
                text: helpers.getSettingsUserName()
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                // Only allow Enter key to be pressed when text has been entered
                EnterKey.enabled: text.length > 0

                // Show 'next' icon to indicate pressing Enter will move the
                // keyboard focus to the next text field in the page
                EnterKey.iconSource: "image://theme/icon-m-enter-next"

                // When Enter key is pressed, move the keyboard focus to the
                // next field
                EnterKey.onClicked: passwordField.focus = true

            }

            TextField {
                id: passwordField
                width: parent.width
                placeholderText: qsTr("Enter Password")
                label: qsTr("Password")
                text: helpers.getSettingsPassword()
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                echoMode: TextInput.PasswordEchoOnEdit

                // Close the on-screen keyboard when enter is clicked
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            TextSwitch {
                id: autologin
                text: qsTr("Automatic login")
                description: qsTr("Allows automatic login when application starts. Can be disabled from Configuration")
                checked: helpers.isAutoLogin()
            }

            Button {
                text: "Login"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    helpers.setSettingsUserName(usernameField.text);
                    helpers.setSettingsPassword(passwordField.text);
                    autologin.checked ? helpers.setAutoLogin() : helpers.clearAutoLogin();
                    pageStack.push(Qt.resolvedUrl("ConnectionPage.qml"),
                                   {'username':usernameField.text,'password':passwordField.text});
                }
            }
        }
    }
}

