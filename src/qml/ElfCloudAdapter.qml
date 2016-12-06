import QtQuick 2.0
import io.thp.pyotherside 1.3

Python {

    id: py

    signal readyForUse()

    signal fetchDataItemChunkCompleted(int parentId, string name, int totalSize, int fetchedSize)
    signal fetchDataItemCompleted(int parentId, string remoteName, string localName)

    signal fetchAndMoveDataItemStarted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemCompleted(int parentId, string name, string localName)
    signal fetchAndMoveDataItemFailed(int parentId, string name, string localName, string reason)

    signal storeDataItemChunkCompleted(int parentId, string remoteName, string localName, int totalSize, int storedSize)
    signal storeDataItemCompleted(int parentId, string remoteName, string localName, int dataItemsLeft)

    signal contentChanged(int containerId) // emitted when content of a container (containerId) has been changed
    signal exceptionOccurred(int id, string message)

    property bool ready: false // True if init done succesfully

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

        setHandler('exception', exceptionOccurred);
        setHandler('completed', _handleCompleted);
        setHandler('failed', _handleFailed);
        setHandler('fetch-dataitem-chunk', _fetchDataItemChunkCb);
        setHandler('fetch-dataitem-completed', _fetchDataItemCompletedCb)
        setHandler('store-dataitem-chunk', _storeDataItemChunkCb);
        setHandler('store-dataitem-completed', _storeDataItemCompletedCb);
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

        if (cbObj.wrapperCb !== undefined)
            cbObj.wrapperCb.apply(null, [cbObj].concat(varArgs));
        else if (cbObj.completedCb !== undefined)
            cbObj.completedCb.apply(null, varArgs);
    }

    function _handleFailed(cbObj) {
        var varArgs = _getVarArgs(_handleFailed, arguments);

        if (cbObj.wrapperFailedCb !== undefined)
            cbObj.wrapperFailedCb.apply(null, [cbObj].concat(varArgs));
        else if (cbObj.failedCb !== undefined)
            cbObj.failedCb.apply(null, varArgs);
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
        var callName = "elfcloudadapter." + func;
        var args = [cbObj].concat(_getVarArgs(_callInCb, arguments));
        cbObj.wrapperCb = wrapper;
        if (py.call_sync(callName, args))
            return cbObj;
        else
            return undefined;
    }

    function _call(func, callback) {
        var callName = "elfcloudadapter." + func;
        var cbObj = _createCbObj(callback);
        var args = [cbObj].concat(_getVarArgs(_call, arguments));
        if (py.call_sync(callName, args))
            return cbObj;
        else
            return undefined;
    }

    function _callWrap(func, callback, wrapper) {
        var callName = "elfcloudadapter." + func;
        var cbObj = _createCbObj(callback, wrapper);
        var args = [cbObj].concat(_getVarArgs(_callWrap, arguments));
        if (py.call_sync(callName, args))
            return cbObj;
        else
            return undefined;
    }

    function _createCbObj2(successCb, failureCb, wrapperSuccess, wrapperFailure) {
        var c = Qt.createComponent("items/ElfCloudAdapterCb.qml");
        var cbObj = c.createObject(elfCloud);

        if (successCb !== undefined)
            cbObj.completedCb = successCb;

        if (failureCb !== undefined)
            cbObj.failedCb = failureCb;

        cbObj.wrapperCb = wrapperSuccess;
        cbObj.wrapperFailedCb = wrapperFailure;

        return cbObj;
    }

    function _call2(func, successCb, failureCb) {
        var callName = "elfcloudadapter." + func;
        var cbObj = _createCbObj2(successCb, failureCb);
        var args = [cbObj].concat(_getVarArgs(_call2, arguments));
        if (py.call_sync(callName, args))
            return cbObj;
        else
            return undefined;
    }

    function getSubscriptionInfo(callback) {
        return _call("getSubscription", callback)
    }


    function connect(username, password, successCb, failureCb) {
         return _call2("connect", successCb, failureCb, username, password);
    }

    function disconnect(callback) {
        return _call("disconnect", callback);
    }

    function isConnected() {
        return py.call_sync("elfcloudadapter.isConnected", []);
    }

    // This function is needed to make a copy from content list got from python since it seems to vanish and cause null pointer accesses
    function _createContentDetailsList(content) {
        var list = []
        for (var i = 0; i < content.length; i++) {
            list.push(content[i]);
        }

        return list
    }

    function listVaults(successCb, failureCb) {
        return _call2("listVaults",
                     function(vaults) {
                        if (successCb !== undefined)
                            successCb(_createContentDetailsList(vaults));
                     }, failureCb);
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

    function _fetchDataItemCompletedCb(parentId, remoteName, localName) {
        fetchDataItemCompleted(parentId, remoteName, localName)
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
        return fetchDataItem(parentId, name, outputPath, function() {
            _fetchAndMoveDataItemCb(parentId, name, outputPath, overwrite);
            _callCbWithArgs(callback, arguments);
        });
    }

    function _storeDataItemChunkCb(parentId, remoteName, localName, totalSize, sizeStored) {
        storeDataItemChunkCompleted(parentId, remoteName, localName, totalSize, sizeStored)
    }

    function _storeDataItemCompletedCb(parentId, remoteName, localName, exception) {
        storeDataItemCompleted(parentId, remoteName, localName, 0);
        contentChanged(parentId);
    }

    function storeDataItems(parentId, localPaths, callback) {

        for (var i = 0; i < localPaths.length; i++) {
            var localName = localPaths[i]
            var remoteName = helpers.getFilenameFromPath(localPaths[i]);
            _call("storeDataItem", undefined, parentId, remoteName, localName);
        }
    }

    function listStores(callback) {
        return _call("listStores", function() { _callCbWithArgs(callback, arguments); })
    }

    function listFetches(callback) {
        return _call("listFetches", function() { _callCbWithArgs(callback, arguments); })
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

    function setEncryptionKey(key, initVector) {
       return py.call_sync("elfcloudadapter.setEncryption", [key, initVector]);
    }

    function clearEncryption() {
        return py.call_sync("elfcloudadapter.clearEncryption");
    }

    Component.onCompleted: {
        if (!py.ready) {
            console.info("elfcloudadapter starting up...");
            console.info("Python version: " + pythonVersion());
            console.info("PyOtherSide version: " + pluginVersion());
            __setHandlers();
            addImportPath(Qt.resolvedUrl("python/"));
            addImportPath(Qt.resolvedUrl("../lib/pycrypto-2.6.1-py3.4-linux-armv7l.egg"));
            addImportPath(Qt.resolvedUrl("../lib/pycrypto-2.6.1-py3.4-linux-i486.egg"));
            addImportPath(Qt.resolvedUrl("../lib/decorator-4.0.9-py3.4.egg"));
            addImportPath(Qt.resolvedUrl("../lib/elfcloud_weasel-1.2.2-py3.4.egg"));
            importModule('elfcloudadapter', function() {  py.ready = true; readyForUse(); });
        }
    }

    onError: console.error("Exception: %1".arg(traceback));
    onExceptionOccurred: console.error("Exception occurred: ", id, message);
}
