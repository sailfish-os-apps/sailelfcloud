import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Show subscription")
                onClicked: pageStack.push(Qt.resolvedUrl("SubscriptionInfoPage.qml"),
                                          {"elfCloud":elfCloud});
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
                title: qsTr("Configurations")
            }

            TextSwitch {
                id: autologin
                text: qsTr("Automatic login")
                description: qsTr("Allows automatic login when application starts.")
                checked: helpers.isAutoLogin()
                onCheckedChanged: {
                    checked ? helpers.setAutoLogin() : helpers.clearAutoLogin();
                }
            }

            TextSwitch {
                id: rememberLogin
                text: qsTr("Remember login")
                description: qsTr("Remembers login information such as username and password.")
                checked: helpers.isRememberLogin()
                onCheckedChanged: {
                    checked ? helpers.setRememberLogin() : helpers.clearRememberLogin();
                }
            }

            Button {
                text: "Forget login information"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    helpers.clearLoginInformation();
                    autologin.checked = false;
                    PageStack.pop();
                }
            }
        }
    }
}


