import QtQuick 2.0

Item {

    property bool ready: false // True if init done succesfully

    signal readyForUse()

    Component.onCompleted: {
        ready = true;
        readyForUse();
    }

}

