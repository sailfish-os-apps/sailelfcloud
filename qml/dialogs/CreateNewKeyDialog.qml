import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property string _key: ""

    signal createdKey(string hash)

    function _create() {
        var keyHexString = _key.substring(0, (keyTypeComboBox.currentIndex == 0) ? 31 :
                                             (keyTypeComboBox.currentIndex == 1) ? 47 : 63);

        console.log("key hex string", keyHexString)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader { id: header }

            Label {
                id: nameField
                anchors.margins: Theme.paddingMedium
                width: parent.width
                wrapMode: Text.Wrap
                text: qsTr("Move your finger around the box below to generate random numbers for the key.")
            }

            ComboBox {
                id: keyTypeComboBox
                currentIndex: 2
                label: qsTr("Algorithm")

                menu: ContextMenu {
                    MenuItem { id: aes128; text: qsTr("AES128") }
                    MenuItem { id: aes192; text: qsTr("AES192") }
                    MenuItem { id: aes256; text: qsTr("AES256") }
                }
            }

            Rectangle {
                id: rectangle
                border.color: "white"
                color: Theme.rgba(Theme.highlightDimmerColor,
                                  Theme.highlightBackgroundOpacity)
                anchors { left: parent.left; right: parent.right; }
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                width: parent.width - Theme.paddingLarge * 2
                height: parent.width / 2

                MouseArea {
                    id: randomizerArea
                    anchors.fill: rectangle
                    preventStealing: true
                    visible: keyGenProgressBar.value !== keyGenProgressBar.maximumValue

                    onPositionChanged: {
                        if (pressed) {
                            _key = helpers.generateKey(_key, mouse.x + mouse.y);
                            keyGenProgressBar.value += 1;

                            if (keyGenProgressBar.value === keyGenProgressBar.maximumValue)
                                keyNameField.focus = true;
                        }
                    }
                }

                Label {
                    width: parent.width
                    anchors.centerIn: parent
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    visible: keyGenProgressBar.value === keyGenProgressBar.maximumValue
                    text: qsTr("Generation completed")
                }
            }

            ProgressBar {
                id: keyGenProgressBar
                width: parent.width
                label: qsTr("Generation progress")
                minimumValue: 0
                maximumValue: (keyTypeComboBox.currentIndex == 0) ? 128 :
                              (keyTypeComboBox.currentIndex == 1) ? 192 : 256
                value: 0
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
        }

        VerticalScrollDecorator { }
    }

    canAccept: keyGenProgressBar.value === keyGenProgressBar.maximumValue && keyNameField.text
    onAccepted: _create()
}
