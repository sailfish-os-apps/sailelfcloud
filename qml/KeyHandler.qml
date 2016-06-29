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
    }

    function findKeyFiles(path) {
        return py.call_sync("keyhandler.findKeyFiles", [path]);
    }

    function readKeyInfoFromFile(path) {
        return py.call_sync("keyhandler.readKeyInfoFromFile", [path]);
    }

    function storeKey(name, description, key, iv, hash) {
        py.call_sync("keyhandler.storeKey", [name, description, key, iv, hash]);
    }

    function getKeys() {
        return py.call_sync("keyhandler.getKeys");
    }

    function getKey(hash) {
        return py.call_sync("keyhandler.getKey", [hash]);
    }

    function isKey(hash) {
        return py.call_sync("keyhandler.isKey", [hash]);
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

        return py.call_sync("keyhandler.removeKey", [hash]);
    }

    function exportKey(hash, dir) {
        return py.call_sync("keyhandler.exportKeyToDir", [hash, dir]);
    }

    Component.onCompleted: {
        if (!py._ready) {
            console.log("keyhandler starting up...");
            console.log("Python version: " + pythonVersion());
            console.log("PyOtherSide version: " + pluginVersion());
            __setHandlers();
            addImportPath(Qt.resolvedUrl("python/"));
            importModule('keyhandler', function() {
                    call_sync('keyhandler.init', [StandardPaths.data])
                    initialized();
                    py._ready = true;
                });
        }
    }

    onError: console.error("Exception: %1".arg(traceback));
}
