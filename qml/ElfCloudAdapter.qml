import QtQuick 2.0
import io.thp.pyotherside 1.4

Python {

    signal connected(bool status, string reason)

    signal fetchDataItemStarted(int parentId, string name, string localName)
    signal fetchDataItemChunkCompleted(int parentId, string name, int totalSize, int sizeFetched)
    signal fetchDataItemCompleted(int parentId, string name, string localName)
    signal fetchDataItemFailed(int parentId, string name, string localName, string reason)

    signal fetchAndMoveDataItemStarted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemChunkCompleted(int parentId, string name, string localName, int totalSize, int sizeFetched)
    signal fetchAndMoveDataItemCompleted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemFailed(int parentId, string name, string localName, string reason)

    signal storeDataItemsStarted(int parentId, var remoteLocalNames)
    signal storeDataItemStarted(int parentId, string remoteName, string localName, int dataItemsLeft)
    signal storeDataItemCompleted(int parentId, string remoteName, string localName, int dataItemsLeft)
    signal storeDataItemFailed(int parentId, string remoteName, string localName, int dataItemsLeft, string reason)
    signal storeDataItemsCompleted(int parentId, var remoteLocalNames)

    signal contentChanged(int containerId)
    signal exceptionOccurred(int id, string message)

    property bool _ready: false // True if init done succesfully

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
        setHandler('store-dataitems-completed', _storeDataItemsCb);
        setHandler('fetch-dataitem-completed', _fetchDataItemCb);
        setHandler('exception', exceptionOccurred);
        setHandler('fetch-dataitem-chunk', _fetchDataItemChunkCb);

        setHandler('completed', _handleCompleted);
    }

    function _callCbWithArgs(cb, args) {
        var argArray = Array.prototype.slice.call(args);
        return cb.apply(null, argArray);
    }

    function _getVarArgs(func, args) {
        return Array.prototype.slice.call(args, func.length);
    }

    function _handleCompleted(cbObj) {
        var varArgs = _getVarArgs(_handleCompleted, arguments);
        console.debug("_handleCompleted", varArgs, cbObj, cbObj.completedCb);
        if (cbObj.completedCb !== undefined)
            cbObj.completedCb.apply(null, varArgs);
    }

    function _createCbObj(callback) {
        var c = Qt.createComponent("items/ElfCloudAdapterCb.qml");
        var cbObj = c.createObject(elfCloud);

        if (callback !== undefined)
            cbObj.completedCb = callback;

        return cbObj;
    }

    function _call(func, callback) {
        var callName = "elfCloudAdapter." + func;
        var cbObj = _createCbObj(callback);
        var args = [cbObj].concat(_getVarArgs(_call, arguments));
        console.debug("_call", callName, args, cbObj.completedCb);
        if (py.call_sync(callName, args))
            return cbObj;
        else
            return undefined;
    }

    function getSubscriptionInfo(callback) {
        return _call("getSubscriptionInfo", callback)
    }


    function connect(username, password, onSuccess) {
        py.call("elfCloudAdapter.connect", [username, password], onSuccess);
    }

    function disconnect(onSuccess) {
        py.call("elfCloudAdapter.disconnect", [], onSuccess);
    }

    // This function is needed to make a copy from content list got from python since it seems to vanish and cause null pointer accesses
    function _createContentDetailsList(content) {
        var list = []
        for (var i = 0; i < content.length; i++) {
            console.log("adding:", content[i].name, content[i].id, content[i].ownerFirstName, content[i].ownerLastName);
            list.push(content[i]);
        }

        return list
    }

    function listVaults(callback) {
        return _call("listVaults", function(vaults) {
                if (callback !== undefined)
                    callback(_createContentDetailsList(vaults));
            });
    }

    function listContent(parentId, callback) {
        return _call("listContent", function(content) {
                if (callback !== undefined)
                    callback(_createContentDetailsList(content));
            }, parentId);
    }

    function getDataItemInfo(parentId, name, callback) {
        return _call("listContent", callback, parentId, name);
    }


    function _fetchDataItemChunkCb(parentId, name, totalSize, sizeFetched) {
        fetchDataItemChunkCompleted(parentId, name, totalSize, sizeFetched)
    }

    function _fetchDataItemCb(status, parentId, name, outputPath) {
        if (status)
            fetchDataItemCompleted(parentId, name, outputPath);
        else
            fetchDataItemFailed(parentId, name, outputPath, "failed");
    }

    function fetchDataItem(parentId, name, outputPath) {
        fetchDataItemStarted(parentId, name, outputPath);
        py.call("elfCloudAdapter.fetchDataItem", [parentId, name, outputPath]);
    }


    function _fetchAndMoveDataItemCb(parentId, name, outputPath, overwrite) {
        if (helpers.moveAndRenameFileAccordingToMime(outputPath, name, overwrite))
            fetchAndMoveDataItemCompleted(parentId, name, outputPath);
        else
            fetchAndMoveDataItemFailed(parentId, name, outputPath, qsTr("Destination file exists"));
    }

    function _fetchAndMoveDataItemChunkCb(parentId, name, outputPath, totalSize, sizeFetched) {
        fetchAndMoveDataItemChunkCompleted(parentId, name, outputPath, totalSize, sizeFetched)
    }

    function fetchAndMoveDataItem(parentId, name, outputPath, overwrite) {
        fetchAndMoveDataItemStarted(parentId, name, outputPath);

        var c = Qt.createComponent("items/ElfCloudAdapterCb.qml");
        var cbObj = c.createObject(elfCloud);
        cbObj.fetchDataItemCompletedCb = function (_parentId, _name) {
                console.log("fetchDataItemCompletedCb!!!!!!!", _name, name)
                if (_parentId === parentId && _name === name) {
                    console.log("fetchDataItemCompletedCb!!!!!!! MATCHSSSSS", _name, name)
                    _fetchAndMoveDataItemCb(parentId, name, outputPath, overwrite);
                    elfCloud.fetchDataItemCompleted.disconnect(this.fetchDataItemCompleted);
                }
            };
        fetchDataItemCompleted.connect(cbObj.fetchDataItemCompleted);
        fetchDataItemChunkCompleted.connect(function (_parentId, _name, totalSize, sizeFetched) {
                if (_parentId === parentId && _name === name)
                    _fetchAndMoveDataItemChunkCb(parentId, name, outputPath, totalSize, sizeFetched);
            });
        py.call("elfCloudAdapter.fetchDataItem", [parentId, name, outputPath]);
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
        py.call("elfCloudAdapter.storeDataItems", [parentId, remoteLocalNames]);
   }

    function removeDataItem(parentId, name, callback) {
        return _call("removeDataItem", function() { _callCbWithArgs(callback, arguments); contentChanged(parentId); },
                     parentId, name)
    }

    function renameDataItem(parentId, oldName, newName, callback) {
        return _call("renameDataItem", function() { _callCbWithArgs(callback, arguments); contentChanged(parentId); },
                     parentId, oldName, newName);
    }

    function addVault(name, callback) {
        return _call("addVault", callback, name)
    }

    function addCluster(parentId, name, callback) {
        return _call("addCluster", function() { _callCbWithArgs(callback, arguments); contentChanged(parentId); },
                     parentId, name)
    }

    function removeCluster(parentId, clusterId, callback) {
        return _call("removeCluster", function() { _callCbWithArgs(callback, arguments); contentChanged(parentId); },
                     clusterId)
    }

    Component.onCompleted: {
        if (!py._ready) {
            console.log("elfCloudAdapter starting up...");
            console.log("Python version: " + pythonVersion());
            console.log("PyOtherSide version: " + pluginVersion());
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
    onExceptionOccurred: console.error("Exception occurred: ", id, message)
}
