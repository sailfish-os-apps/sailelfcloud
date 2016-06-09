import QtQuick 2.0
import io.thp.pyotherside 1.2
import harbour.sailelfcloud.helpers 1.0

Python {

    signal connected(bool status, string reason)
    signal uploadStarted(int parentId)
    signal uploadFileCompleted(int parentId, string name, string localName)
    signal uploadCompleted(int parentId)

    signal fetchDataItemStarted(int parentId, string name, string localName)
    signal fetchDataItemCompleted(int parentId, string name, string localName)
    signal fetchDataItemFailed(int parentId, string name, string localName, string reason)

    signal fetchAndMoveDataItemStarted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemCompleted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemFailed(int parentId, string name, string localName, string reason)

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
        setHandler('store-started', uploadStarted);
        setHandler('store-completed', uploadCompleted);
        setHandler('store-dataitem-completed', uploadFileCompleted);
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

    function readPlainFile(filename, onSuccess) {
        py.call("elfCloudAdapter.readPlainFile", [filename], onSuccess);
    }

    function readBinFile(filename, onSuccess) {
        py.call("elfCloudAdapter.readBinFile", [filename], onSuccess);
    }

    function getSubscriptionInfo(onSuccess) {
        py.call("elfCloudAdapter.getSubscriptionInfo", [], onSuccess);
    }

    function _storeDataItemCb(status, parentId, localPath, remoteName) {
        console.log("Uploaded", status, parentId, localPath, remoteName);
    }

    WorkerScript {
       id: dataItemStoreWorker
       source: "script/DataItemUploader.js"

       onMessage: {
           py.call("elfCloudAdapter.storeDataItem", [messageObject.parentId,
                                                     messageObject.remoteName,
                                                     messageObject.localPath],
                   function(status) { _storeDataItemCb(status, messageObject.parentId,
                                                       messageObject.localPath,
                                                       messageObject.remoteName); });
       }
    }

    function storeDataItems(parentId, localPaths) {
        var remoteNames = []

        for (var i = 0; i < localPaths.length; i++) {
            remoteNames.push(helpers.getFilenameFromPath(localPaths[i]));
        }

        dataItemStoreWorker.sendMessage({"parentId":parentId,"localPaths":ĺocalPaths,"remoteNames":remoteNames});
    }

    function removeFile(parentId, filename, onSuccess) {
        py.call("elfCloudAdapter.removeDataItem", [parentId, filename], onSuccess);
    }

    function renameDataItem(parentId, oldName, newName, onSuccess) {
        py.call("elfCloudAdapter.renameDataItem", [parentId, oldName, newName], onSuccess);
    }

    function addVault(name, onSuccess) {
        py.call("elfCloudAdapter.addVault", [name], onSuccess);
    }

    function addCluster(parentId, name, onSuccess) {
        py.call("elfCloudAdapter.addCluster", [parentId, name], onSuccess);
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
