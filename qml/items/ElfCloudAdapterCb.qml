import QtQuick 2.0


QtObject {
    id: obj

    function _noop(data) {
        console.debug("Noop called", Array.prototype.slice.call(data, _noop.length))
    }

    property var completedCb: _noop    // Callback from user
    property var wrapperCb: undefined  // Wrapping callback from ElfCloudAdapter.qml

    property var failedCb: _noop    // Callback from user for failure
    property var wrapperFailedCb: undefined  // Wrapping failure callback from ElfCloudAdapter.qml

    function invalidate() {
        completedCb = _noop;
        failedCb = _noop;
    }

    function unsetWrapper() {
        wrapperCb = undefined;
        wrapperFailedCb = undefined;
    }

    Component.onDestruction: {
        invalidate();
        unsetWrapper();
    }
}

