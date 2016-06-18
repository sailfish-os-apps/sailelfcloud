import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."


Page {
    id: page
    property string p: "testki"

    signal populate(var infoItems)

    onPopulate: {
        for (var i = 0; i < infoItems.length; i++) {
            infoModel.append(infoItems[i]); // every element in info is {'fieldName':name,'fieldValue':value} mappings
        }
    }

    function subscription(info) {
        console.log(p)
        page.populate(info)
    }

    Component.onCompleted: {
        //var c = Qt.createComponent("../items/ElfCloudAdapterCb.qml");
        //var cbObj = c.createObject(elfCloud);
        //cbObj.subscriptionCb = subscription;
        elfCloud.getSubscriptionInfo(subscription);
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
