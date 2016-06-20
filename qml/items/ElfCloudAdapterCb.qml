import QtQuick 2.0


QtObject {
    id: obj

    function _noop(data) {
        console.debug("Noop called", Array.prototype.slice.call(data, _noop.length))
    }

    property var completedCb: _noop    // Callback from user
    property var wrapperCb: undefined  // Wrapping callback from ElfCloudAdapter.qml

    function invalidate() {
        completedCb = _noop;
    }

    function unsetWrapper() {
        wrapperCb = undefined;
    }

    Component.onDestruction: {
        invalidate();
        unsetWrapper();
    }
}

