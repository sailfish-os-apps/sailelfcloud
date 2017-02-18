import QtQuick 2.0

Item {

    property bool ready: false // True if init done succesfully

    signal readyForUse()
    signal storeDataItemStarted(int parentId, string remoteName, string localName)
    signal storeDataItemChunkCompleted(int parentId, string remoteName, string localName, int totalSize, int storedSize)
    signal storeDataItemCompleted(int parentId, string remoteName, string localName)
    signal fetchDataItemStarted(int parentId, string remoteName, string localName)
    signal fetchDataItemChunkCompleted(int parentId, string remoteName, int totalSize, int fetchedSize)
    signal fetchDataItemCompleted(int parentId, string remoteName, string localName)

    signal tst_connect(string username, string password, var successCb, var failureCb)
    signal tst_listStores(var callback)
    signal tst_listFetches(var callback)

    function connect(username, password, successCb, failureCb) {
        tst_connect(username, password, successCb, failureCb);
    }

    function listStores(callback) {
        tst_listStores(callback);
    }

    function listFetches(callback) {
        tst_listFetches(callback);
    }


    Component.onCompleted: {
        ready = true;
        readyForUse();
    }

}

