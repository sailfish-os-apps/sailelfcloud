import QtQuick 2.0


QtObject {
    id: obj

    property var subscriptionCb: function() {}
    function subscription(infoItem) { subscriptionCb(infoItem); }

    property var fetchDataItemCompletedCb: function() {}
    function fetchDataItemCompleted(parentId, name) { fetchDataItemCompletedCb(parentId, name); }

    property var completedCb: function(_data) {}
    function callCompleted(data) {
        completedCb(data);
    }


    Component.onDestruction: {
        elfCloud.fetchDataItemCompleted.disconnect(obj.fetchDataItemCompleted);
    }
}

