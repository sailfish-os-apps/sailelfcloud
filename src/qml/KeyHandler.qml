import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.3

Python {

    id: py

    signal readyForUse()

    property bool ready: false
    property string _keyringpassword

    function _getVarArgs(func, args) {
        return Array.prototype.slice.call(args, func.length);
    }

    function _asycCall(func, callback) {
        var argArray = _getVarArgs(_asycCall, arguments);
        var callName = "keyhandler." + func;
        return py.call(callName, argArray, callback);
    }

    function _syncCall(func) {
        var argArray = _getVarArgs(_syncCall, arguments);
        var callString = "keyhandler." + func + "(";
        var i = 0;

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
        return _syncCall("findKeyFiles", path);
    }

    function readKeyInfoFromFile(path) {
        return _syncCall("readKeyInfoFromFile", path);
    }

    function storeKey(name, description, key, iv, hash) {
        _syncCall("storeKey", name, description, key, iv, hash);
    }

    function getKeys() {
        return _syncCall("getKeys");
    }

    function getKeysAsJsonString() {
        return _syncCall("getKeysAsJsonString");
    }

    function getKey(hash) {
        return _syncCall("getKey", hash);
    }

    function isKey(hash) {
        return _syncCall("isKey", hash);
    }

    function isKeyWithName(name) {
        return _syncCall("isKeyWithName", name);
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

        return _syncCall("removeKey", hash);
    }

    function exportKey(hash, dir) {
        return _syncCall("exportKeyToDir", hash, dir);
    }

    function modifyKey(hash, name, description) {
        return _syncCall("modifyKey", hash, name, description);
    }

    function convertKeyInfo2Json(keyinfo) {
        return _syncCall("convertKeyInfo2Json", keyinfo);
    }

    function convertJson2KeyInfo(jsonDocument) {
        return _syncCall("convertJson2KeyInfo", jsonDocument);
    }

    function mergeKeyrings(keyring1, keyring2) {
        return _syncCall("mergeKeyrings", keyring1, keyring2);
    }

    function mergeJsonKeyrings(keyring1, keyring2) {
        return _syncCall("mergeJsonKeyrings", keyring1, keyring2);
    }

    function secureInit(cb) {
        _asycCall('secureInit', cb, StandardPaths.data, _keyringpassword);
    }

    function setKeyringPassword(passwd) {
        _keyringpassword = passwd;
    }

    function _init() {
        _syncCall('init', StandardPaths.data);
    }

    Component.onCompleted: {
        if (!py.ready) {
            console.info("keyhandler starting up...");
            console.info("Python version: " + pythonVersion());
            console.info("PyOtherSide version: " + pluginVersion());
            addImportPath(Qt.resolvedUrl("python/"));
            addImportPath(Qt.resolvedUrl("../lib/pycrypto-2.6.1-py3.4-linux-armv7l.egg"));
            addImportPath(Qt.resolvedUrl("../lib/pycrypto-2.6.1-py3.4-linux-i486.egg"));
            importModule_sync('keyhandler');
            _init();
            py.ready = true; readyForUse();
        }
    }

    onError: console.error("Exception: %1".arg(traceback));
}
