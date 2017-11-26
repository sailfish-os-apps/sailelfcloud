import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    function _populateKeyList() {
        var keys = keyHandler.getKeys();
        var activeIndex = 0;
        keyListModel.clear();
        keyListModel.append({"key": {"name": qsTr("disable encryption"), "hash": "0"}});

        for (var i = 0; i < keys.length; i++) {

            if (keys[i]['hash'] === helpers.getActiveKey())
                activeIndex = i+1; // increase by one since we have 'disable encryption' as the first one

            keyListModel.append({"key": keys[i]});
        }

        // BUG: Sailfish combobox does not react if only currentIndex is set.
        //      Also currentItem must be set in ordet to select current item.
        keyListCompoBox.currentIndex = activeIndex;
        keyListCompoBox.currentItem = keyListCompoBox.menu.children[activeIndex]
    }

    function _chooseActiveKey(key) {
        if (key["hash"] !== "0") {
            helpers.setActiveKey(key["hash"]);
        }
        else
            helpers.clearActiveKey();
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            if (keyHandler.isReady())
                _populateKeyList();
            else
                keyHandler.initialized.connect(_populateKeyList); // keyhandler may get loaded slowly
        }

    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height


        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Configuration")
                onClicked: {
                    var page = pageStack.push(Qt.resolvedUrl("ConfigPage.qml"));
                }
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

            PasswordField {
                id: passwordField
                width: parent.width
                placeholderText: qsTr("Enter Password")
                label: qsTr("Password")
                text: helpers.getSettingsPassword()
                showEchoModeToggle: true

                // Only allow Enter key to be pressed when text has been entered
                EnterKey.enabled: text.length > 0

                // Show 'next' icon to indicate pressing Enter will move the
                // keyboard focus to the next text field in the page
                EnterKey.iconSource: "image://theme/icon-m-enter-next"

                // When Enter key is pressed, move the keyboard focus to the
                // next field
                EnterKey.onClicked: keyringPasswordField.focus = true
            }

            PasswordField {
                id: keyringPasswordField
                width: parent.width
                placeholderText: qsTr("Enter Keyring Password")
                label: qsTr("Keyring Password")
                text: helpers.getSettingsKeyringPassword()
                showEchoModeToggle: true

                // Only allow Enter key to be pressed when text has been entered
                EnterKey.enabled: text.length > 0

                // Close the on-screen keyboard when enter is clicked
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            Text
            {
                visible: keyListModel.count < 2 // There is always default item (encryption disabled) in the list so at least 2 items needed
                anchors { left: parent.left; right: parent.right;
                          leftMargin: Theme.horizontalPageMargin; rightMargin: Theme.horizontalPageMargin }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignJustify
                color: Theme.secondaryHighlightColor
                textFormat: Text.RichText
                font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
                text: "<style>a:link { color: " + Theme.highlightColor + "; }</style>" +
                      qsTr("No encryption keys found.") + " " +
                      qsTr("Click <a href=\"EncryptionConfigPage.qml\">here</a> to configure.")
                onLinkActivated:
                {
                    pageStack.push(Qt.resolvedUrl(link));
                }
            }

            ComboBox {
                id: keyListCompoBox
                visible: keyListModel.count > 1 // at least two items in list before we activate this
                description: qsTr("Active encryption key")
                anchors { left: parent.left; right: parent.right }

                menu: ContextMenu {
                        id: keyListContextMenu
                        Repeater {
                            id: keyListRepeater
                            model: ListModel { id: keyListModel }
                            delegate: MenuItem {
                                    text: key["name"]
                                    onClicked: _chooseActiveKey(key);
                                }
                        }
                    }
            }

            TextSwitch {
                id: autologin
                text: qsTr("Automatic login")
                description: qsTr("Login automatically when application starts.")
                checked: helpers.isAutoLogin()
            }

            Button {
                text: "Login"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    helpers.isRememberLogin() ? helpers.setSettingsUserNamePassword(usernameField.text, passwordField.text) :
                                                helpers.clearSettingsUserNamePassword();
                    autologin.checked ? helpers.setAutoLogin() : helpers.clearAutoLogin();
                    pageStack.push(Qt.resolvedUrl("ConnectionPage.qml"),
                                   {'username':usernameField.text,'password':passwordField.text});
                }
            }
            Text
            {
                anchors { left: parent.left; right: parent.right;
                    leftMargin: Theme.horizontalPageMargin; rightMargin: Theme.horizontalPageMargin }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignJustify
                color: Theme.secondaryHighlightColor
                textFormat: Text.RichText
                font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
                text: "<style>a:link { color: " + Theme.highlightColor + "; }</style>" +
                      qsTr("See <a href=\"ConfigPage.qml\">Config page</a> for more properties to change.")
                onLinkActivated:
                {
                    pageStack.push(Qt.resolvedUrl(link));
                }
            }
        }
    }
}

