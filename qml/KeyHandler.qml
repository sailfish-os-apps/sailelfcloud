import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4

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
            return [key["data"], key["iv"]];
        }
        return undefined
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
