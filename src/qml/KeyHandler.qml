import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.3

Python {

    id: py

    signal initialized()

    property bool _ready: false

    function isReady() {
        return _ready;
    }

    function _syncCallPy(func, args) {
        var argArray = Array.prototype.slice.call(arguments);
        var callString = func + "(";
        var i = 1; // skip first arg since it is python call name 'func'

        while (i < argArray.length) {
            if (typeof(argArray[i]) === 'number')
               callString += argArray[i].toString;
            else if (typeof(argArray[i]) === 'string')
                callString += '\'' + argArray[i] + '\'';
            else
                console.debug("unknown type:", typeof(argArray[i]), argArray[i]);

            i++;

            if (i < argArray.length)
                callString += ","
        }

        callString += ")";

        return py.evaluate(callString);
    }

    function findKeyFiles(path) {
        return _syncCallPy("keyhandler.findKeyFiles", path);
    }

    function readKeyInfoFromFile(path) {
        return _syncCallPy("keyhandler.readKeyInfoFromFile", path);
    }

    function storeKey(name, description, key, iv, hash) {
        _syncCallPy("keyhandler.storeKey", name, description, key, iv, hash);
    }

    function getKeys() {
        return _syncCallPy("keyhandler.getKeys");
    }

    function getKeysAsJsonString() {
        return _syncCallPy("keyhandler.getKeysAsJsonString");
    }

    function getKey(hash) {
        return _syncCallPy("keyhandler.getKey", hash);
    }

    function isKey(hash) {
        return _syncCallPy("keyhandler.isKey", hash);
    }

    function isKeyWithName(name) {
        return _syncCallPy("keyhandler.isKeyWithName", name);
    }

    function getActiveKeyAndIv() {
        var activeKeyHash = helpers.getActiveKey();

        if (activeKeyHash) {
            var key = keyHandler.getKey(activeKeyHash);
            return [key["key"], key["iv"]];
        }
        return undefined
    }

    function isActiveKey(hash) {
        var activeKeyHash = helpers.getActiveKey();
        return hash === activeKeyHash
    }

    function removeKey(hash) {
        if (isActiveKey(hash))
            helpers.clearActiveKey();

        return _syncCallPy("keyhandler.removeKey", hash);
    }

    function exportKey(hash, dir) {
        return _syncCallPy("keyhandler.exportKeyToDir", hash, dir);
    }

    function modifyKey(hash, name, description) {
        return _syncCallPy("keyhandler.modifyKey", hash, name, description);
    }

    function convertKeyInfo2Json(keyinfo) {
        return _syncCallPy("keyhandler.convertKeyInfo2Json", keyinfo);
    }

    function convertJson2KeyInfo(jsonDocument) {
        return _syncCallPy("keyhandler.convertJson2KeyInfo", jsonDocument);
    }

    function mergeKeyrings(keyring1, keyring2) {
        return _syncCallPy("keyhandler.mergeKeyrings", keyring1, keyring2);
    }

    function mergeJsonKeyrings(keyring1, keyring2) {
        return _syncCallPy("keyhandler.mergeJsonKeyrings", keyring1, keyring2);
    }

    Component.onCompleted: {
        if (!py._ready) {
            console.info("keyhandler starting up...");
            console.info("Python version: " + pythonVersion());
            console.info("PyOtherSide version: " + pluginVersion());
            addImportPath(Qt.resolvedUrl("python/"));
            importModule('keyhandler', function() {
                    _syncCallPy('keyhandler.init', StandardPaths.data);
                    initialized();
                    py._ready = true;
                });
        }
    }

    onError: console.error("Exception: %1".arg(traceback));
}
