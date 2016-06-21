import QtQuick 2.0
import io.thp.pyotherside 1.4

Python {

    signal connected(bool status, string reason)

    signal fetchDataItemChunkCompleted(int parentId, string name, int totalSize, int fetchedSize)

    signal fetchAndMoveDataItemStarted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemCompleted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemFailed(int parentId, string name, string localName, string reason)

    signal storeDataItemChunkCompleted(int parentId, string remoteName, string localName, int totalSize, int storedSize)

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
        setHandler('exception', exceptionOccurred);
        setHandler('fetch-dataitem-chunk', _fetchDataItemChunkCb);
        setHandler('store-dataitem-chunk', _storeDataItemChunkCb);
        setHandler('completed', _handleCompleted);
    }

    function _callCbWithArgs(cb, args) {
        var argArray = Array.prototype.slice.call(args);

        if (cb !== undefined)
            return cb.apply(null, argArray);
        else
            return undefined
    }

    function _getVarArgs(func, args) {
        return Array.prototype.slice.call(args, func.length);
    }

    function _handleCompleted(cbObj) {
        var varArgs = _getVarArgs(_handleCompleted, arguments);
        console.debug("_handleCompleted", varArgs, cbObj, cbObj.completedCb);

        if (cbObj.wrapperCb !== undefined)
            cbObj.wrapperCb.apply(null, [cbObj].concat(varArgs));
        else if (cbObj.completedCb !== undefined)
            cbObj.completedCb.apply(null, varArgs);
    }

    function _createCbObj(callback, wrapper) {
        var c = Qt.createComponent("items/ElfCloudAdapterCb.qml");
        var cbObj = c.createObject(elfCloud);

        if (callback !== undefined)
            cbObj.completedCb = callback;

        cbObj.wrapperCb = wrapper;

        return cbObj;
    }

    function _callInCb(cbObj, func, wrapper) {
        var callName = "elfCloudAdapter." + func;
        var args = [cbObj].concat(_getVarArgs(_callInCb, arguments));
        cbObj.wrapperCb = wrapper;
        console.debug("_callInCb", callName, args, cbObj.completedCb, cbObj.wrapperCb);
        if (py.call_sync(callName, args))
            return cbObj;
        else
            return undefined;
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

    function _callWrap(func, callback, wrapper) {
        var callName = "elfCloudAdapter." + func;
        var cbObj = _createCbObj(callback, wrapper);
        var args = [cbObj].concat(_getVarArgs(_callWrap, arguments));
        console.debug("_callWrap", callName, args, cbObj.completedCb, cbObj.wrapperCb);
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

    function isConnected() {
        return py.call_sync("elfCloudAdapter.isConnected", []);
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
        return _call("getDataItemInfo", callback, parentId, name);
    }


    function _fetchDataItemChunkCb(parentId, name, totalSize, sizeFetched) {
        fetchDataItemChunkCompleted(parentId, name, totalSize, sizeFetched)
    }

    function fetchDataItem(parentId, name, outputPath, callback) {
        return _call("fetchDataItem", callback, parentId, name, outputPath);
    }

    function _fetchAndMoveDataItemCb(parentId, name, outputPath, overwrite) {
        if (helpers.moveAndRenameFileAccordingToMime(outputPath, name, overwrite)) {
            fetchAndMoveDataItemCompleted(parentId, name, outputPath);
            return true;
        } else {
            fetchAndMoveDataItemFailed(parentId, name, outputPath, qsTr("Destination file exists"));
            return false;
        }
    }

    function fetchAndMoveDataItem(parentId, name, outputPath, overwrite, callback) {
        fetchAndMoveDataItemStarted(parentId, name, outputPath);
        return _call("fetchDataItem", function() {
                var rc = _fetchAndMoveDataItemCb(parentId, name, outputPath, overwrite);
                _callCbWithArgs(callback, arguments);
            }, parentId, name, outputPath)
    }

    function _storeDataItemChunkCb(parentId, remoteName, localName, totalSize, sizeStored) {
        storeDataItemChunkCompleted(parentId, remoteName, localName, totalSize, sizeStored)
    }

    function _storeDataItemsCb(cbObj, parentId, remoteLocalNames, index) {

        storeDataItemCompleted(parentId, remoteLocalNames[index][0], remoteLocalNames[index][1], remoteLocalNames.length-index);

        if (++index < remoteLocalNames.length) {
            storeDataItemStarted(parentId, remoteLocalNames[index][0], remoteLocalNames[index][1], remoteLocalNames.length-index);
            _callInCb(cbObj, "storeDataItem", function(cbObj) { _storeDataItemsCb(cbObj, parentId, remoteLocalNames, index); },
                parentId, remoteLocalNames[index][0], remoteLocalNames[index][1]);
        } else {
            cbObj.unsetWrapper();
            _handleCompleted(cbObj, parentId, remoteLocalNames);
            storeDataItemsCompleted(parentId, remoteLocalNames);
        }
    }

    function storeDataItems(parentId, localPaths, callback) {
        var remoteLocalNames = []

        for (var i = 0; i < localPaths.length; i++) {
            var localName = localPaths[i]
            var remoteName = helpers.getFilenameFromPath(localPaths[i]);
            remoteLocalNames.push([remoteName,localName]);
        }

        storeDataItemsStarted(parentId, remoteLocalNames);
        storeDataItemStarted(parentId, remoteLocalNames[0][0], remoteLocalNames[0][1], remoteLocalNames.length);
        return _callWrap("storeDataItem", callback,
                         function(cbObj) { _storeDataItemsCb(cbObj, parentId, remoteLocalNames, 0); },
                         parentId, remoteLocalNames[0][0], remoteLocalNames[0][1])
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
            importModule('elfCloudAdapter', function() {});
            py._ready = true;
        }
    }

    onError: console.error("Exception: %1".arg(traceback));
    onExceptionOccurred: console.error("Exception occurred: ", id, message)
}
