import QtQuick 2.0
import io.thp.pyotherside 1.2
import harbour.sailelfcloud.helpers 1.0

Python {

    signal connected(bool status, string reason)

    signal fetchDataItemStarted(int parentId, string name, string localName)
    signal fetchDataItemCompleted(int parentId, string name, string localName)
    signal fetchDataItemFailed(int parentId, string name, string localName, string reason)

    signal fetchAndMoveDataItemStarted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemCompleted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemFailed(int parentId, string name, string localName, string reason)

    signal storeDataItemsStarted(int parentId, var remoteLocalNames)
    signal storeDataItemStarted(int parentId, string remoteName, string localName, int dataItemsLeft)
    signal storeDataItemCompleted(int parentId, string remoteName, string localName, int dataItemsLeft)
    signal storeDataItemFailed(int parentId, string remoteName, string localName, int dataItemsLeft, string reason)
    signal storeDataItemsCompleted(int parentId, var remoteLocalNames)

    signal vaultAdded(string name)

    signal clusterAdded(int parentId, string name)
    signal clusterRemoved(int id)

    signal dataItemRemoved(int parentId, string name)

    signal dataItemRenamed(int parentId, string oldName, string newName)

    property bool _ready: false // True if init done succesfully
    property var  _helpers: Helpers { }

    id: py

    // Sets up handlers for events and signals from python module
    function __setHandlers() {
        setHandler('log-d', function (text) {
                    console.debug(text);
                });
        setHandler('log-i', function (text) {
                    console.info(text);
                });
        setHandler('log-e', function (text) {
                    console.error(text);
                });

        setHandler('connected', connected);
        setHandler('store-dataitem-completed', _storeDataItemCb);
    }

    function connect(username, password, onSuccess) {
        py.call("elfCloudAdapter.connect", [username, password], onSuccess);
    }

    function disconnect(onSuccess) {
        py.call("elfCloudAdapter.disconnect", [], onSuccess);
    }

    function _createContentDetailsList(content) {
        var list = []
        for (var i = 0; i < content.length; i++) {
            console.log("adding:", content[i].name, content[i].id, content[i].ownerFirstName, content[i].ownerLastName);
            list.push(content[i]);
        }

        return list
    }


    function listVaults(onSuccess) {
        py.call("elfCloudAdapter.listVaults", [],
                function(vaults) {onSuccess(_createContentDetailsList(vaults))});
    }

    function listContent(parentId, onSuccess) {
        py.call("elfCloudAdapter.listContent", [parentId],
                function(content) {onSuccess(_createContentDetailsList(content))});
    }

    function getDataItemInfo(parentId, name, onSuccess) {
        py.call("elfCloudAdapter.getDataItemInfo", [parentId, name], onSuccess);
    }

    function _fetchDataItemCb(status, parentId, name, outputPath) {
        if (status)
            fetchDataItemCompleted(parentId, name, outputPath);
        else
            fetchDataItemFailed(parentId, name, outputPath, "failed");
    }

    function fetchDataItem(parentId, name, outputPath) {
        fetchDataItemStarted(parentId, name, outputPath);
        py.call("elfCloudAdapter.fetchDataItem", [parentId, name, outputPath],
                function(status) {_fetchDataItemCb(status, parentId, name, outputPath); });
    }


    function _fetchAndMoveDataItemCb(status, parentId, name, outputPath, overwrite) {
        if (status) {
            if (helpers.moveAndRenameFileAccordingToMime(outputPath, name, overwrite))
                fetchAndMoveDataItemCompleted(parentId, name, outputPath);
            else
                fetchAndMoveDataItemFailed(parentId, name, outputPath, qsTr("Destination file exists"));
        }
        else
            fetchAndMoveDataItemFailed(parentId, name, outputPath, "failed");
    }

    function fetchAndMoveDataItem(parentId, name, outputPath, overwrite) {
        fetchDataItemStarted(parentId, name, outputPath);
        py.call("elfCloudAdapter.fetchDataItem", [parentId, name, outputPath],
                function(status) { _fetchAndMoveDataItemCb(status, parentId, name, outputPath, overwrite); });
    }

    function getSubscriptionInfo(onSuccess) {
        py.call("elfCloudAdapter.getSubscriptionInfo", [], onSuccess);
    }

    function _storeDataItemCb(status, parentId, remoteName, localName, dataItemsLeft) {
        if (status)
            storeDataItemCompleted(parentId, remoteName, localName, dataItemsLeft);
        else
            storeDataItemFailed(parentId, remoteName, localName, dataItemsLeft, "failed");
    }

    function _storeDataItemsCb(status, parentId, remoteLocalNames) {
        storeDataItemsCompleted(parentId, remoteLocalNames);
    }

    function storeDataItems(parentId, localPaths) {
        var remoteLocalNames = []

        for (var i = 0; i < localPaths.length; i++) {
            var localName = localPaths[i]
            var remoteName = helpers.getFilenameFromPath(localPaths[i]);
            remoteLocalNames.push([remoteName,localName]);
        }

        storeDataItemsStarted(parentId, remoteLocalNames);
        py.call("elfCloudAdapter.storeDataItems", [parentId, remoteLocalNames],
                function(status) { _storeDataItemsCb(status, parentId, remoteLocalNames); });
   }

    function _removeDataItemCb(status, parentId, name) {
        dataItemRemoved(parentId, name);
    }

    function removeDataItem(parentId, name) {
        py.call("elfCloudAdapter.removeDataItem", [parentId, name],
                function(status) { _removeDataItemCb(status, parentId, name); });
    }

    function _renameDataItemCb(status, parentId, oldName, newName) {
        dataItemRenamed(parentId, oldName, newName);
    }

    function renameDataItem(parentId, oldName, newName) {
        py.call("elfCloudAdapter.renameDataItem", [parentId, oldName, newName],
                function(status) { _renameDataItemCb(status, parentId, oldName, newName); });
    }

    function _addVaultCb(status, name) {
        vaultAdded(name);
    }

    function addVault(name) {
        py.call("elfCloudAdapter.addVault", [name],
                function(status) { _addVaultCb(status, name); });
    }

    function _addClusterCb(status, parentId, name) {
        clusterAdded(parentId, name);
    }

    function addCluster(parentId, name) {
        py.call("elfCloudAdapter.addCluster", [parentId, name],
                function(status) { _addClusterCb(status, parentId, name); });
    }

    function _removeClusterCb(status, id) {
        clusterRemoved(id);
    }

    function removeCluster(id) {
        py.call("elfCloudAdapter.removeCluster", [id],
                function(status) { _removeClusterCb(status, id); });
    }

    Component.onCompleted: {
        if (!py._ready) {
            console.log("elfCloudAdapter starting up...");
            console.log("Python version: " + pythonVersion());
            __setHandlers();
            addImportPath(Qt.resolvedUrl("python/"));
            addImportPath(Qt.resolvedUrl("../lib/pyaes-0.1.0-py3.4.egg"));
            addImportPath(Qt.resolvedUrl("../lib/decorator-4.0.9-py3.4.egg"));
            addImportPath(Qt.resolvedUrl("../lib/elfcloud_weasel-1.2.2-py3.4.egg"));
            importModule('elfCloudAdapter', function() {
                });
            py._ready = true;
        }
    }

    onError: console.error("Exception: %1".arg(traceback));
}
