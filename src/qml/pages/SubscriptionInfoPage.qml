import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."


Page {
    id: page
    property var _asycCallRef: undefined // Reference to async call so that we can clean it
                                         // when closing the page and call is still in progress.
                                         // This prevent accessing undefined variables.

    function _subscriptionCb(infoItems) {
        console.log("!!!!!!!!!!!!!", infoItems.length, infoItems)
        for (var i in infoItems) {
            infoModel.append({"fieldName":i, "fieldValue":infoItems[i]});
        }
    }

    Component.onCompleted: {
        // Note that we store async call reference so that we can invalidate it
        // if the elcCloud call is still in progress but this page is being closed.
        _asycCallRef = elfCloud.getSubscriptionInfo(_subscriptionCb);
    }

    Component.onDestruction: {
        if (_asycCallRef !== undefined)
            _asycCallRef.invalidate();
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
