import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."


Page {
    id: page

    Component.onCompleted: {
        elfCloud.getSubscriptionInfo(function(info) {
            for (var i = 0; i < info.length; i++) {
                infoModel.append(info[i]); // every element in info is {'fieldName':name,'fieldValue':value} mappings
            }
        });
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Subscription Info")
        }

        model: ListModel {
            id: infoModel
        }

        delegate: Item {
            width: parent.width
            height: Theme.itemSizeSmall

            DetailItem {
                label: qsTr(fieldName)
                value: {
                    return fieldValue;
                }
            }
        }
    }
}
