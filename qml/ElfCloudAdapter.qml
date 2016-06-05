import QtQuick 2.0
import io.thp.pyotherside 1.2
import harbour.sailelfcloud.helpers 1.0

Python {

    signal uploadStarted(int parentId)
    signal uploadFileCompleted(int parentId, string remotePath, string localPath)
    signal downloadFileCompleted(int parentId, string remotePath, string localPath)
    signal uploadCompleted(int parentId)
    signal downloadCompleted(int parentId)


    property bool _ready: false // True if init done succesfully
    property var  _componentDetailsComp: Qt.createComponent("ContentDetailsType.qml")
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

    // Adapter for converting conteiner details from elfCloudAdapter.py to
    // our internal representation ContainerDetailsType
    function _createContentDetailsList(content) {
        var list = []
        for (var i = 0; i < content.length; i++) {
            console.log("adding:", content[i].name, content[i].id, content[i].ownerFirstName, content[i].ownerLastName);
            list.push(_componentDetailsComp.createObject(py, // we will be the parent
                                                        {"contentName"    :content[i].name,
                                                         "contentId"      :content[i].id,
                                                         "contentParentId":content[i].parentId,
                                                         "contentSize"    :content[i].size,
                                                         "contentType"    :content[i].type,
                                                         "contentOwnerFirstName" :content[i].ownerFirstName,
                                                         "contentOwnerLastName" :content[i].ownerLastName}));
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

    function fetchData(parentId, name, onSuccess) {
        py.call("elfCloudAdapter.fetchDataItem", [parentId, name], onSuccess);
    }

    function readFile(filename, onSuccess) {
        py.call("elfCloudAdapter.readFile", [filename],
                function(result) {onSuccess(result[0], result[1]);});
    }

    function getSubscriptionInfo(onSuccess) {
        py.call("elfCloudAdapter.getSubscriptionInfo", [], onSuccess);
    }

    function uploadFile(parentId, path, onSuccess) {
        var remoteName = _helpers.getFilenameFromPath(path);
        py.call("elfCloudAdapter.storeDataItem", [parentId, remoteName, path], onSuccess);
    }

    function uploadFiles(parentId, localPaths, onSuccess) {
        var localRemotePaths = []
        for (var i = 0; i < localPaths.length; i++) {
            var localPath = localPaths[i];
            var remoteName = _helpers.getFilenameFromPath(localPaths[i]);
            localRemotePaths.push([localPath,remoteName]);
        }
        py.call("elfCloudAdapter.storeDataItems", [parentId, localRemotePaths], onSuccess);
    }

    function removeFile(parentId, filename, onSuccess) {
        py.call("elfCloudAdapter.removeDataItem", [parentId, filename], onSuccess);
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

    onError: console.log("Error: %1".arg(traceback));
}
