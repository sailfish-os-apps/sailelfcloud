import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4

Python {

    id: py

    property bool _ready: false

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

    Component.onCompleted: {
        if (!py._ready) {
            console.log("keyhandler starting up...");
            console.log("Python version: " + pythonVersion());
            console.log("PyOtherSide version: " + pluginVersion());
            __setHandlers();
            addImportPath(Qt.resolvedUrl("python/"));
            importModule('keyhandler', function() {
                    call_sync('keyhandler.init', [StandardPaths.data])
                });
            py._ready = true;
        }
    }

    onError: console.error("Exception: %1".arg(traceback));
}
