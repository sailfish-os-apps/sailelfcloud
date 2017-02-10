import QtQuick 2.0
import Sailfish.Silica 1.0
import "cover"
import "items"

ApplicationWindow
{
    id: application

    property var elfCloud: ElfCloudAdapter { }
    property var keyHandler: KeyHandler { }
    property var notifications: Notifications { }

    function setItemNameToCover(name) {
        coverPage.location = name
    }

    function _handleException(id, message) {
        pageStack.completeAnimation()
        pageStack.push(Qt.resolvedUrl("pages/ProblemPage.qml"),
                       {"id":id,
                        "message":message});
    }

    Component.onCompleted: {
        elfCloud.exceptionOccurred.connect(_handleException);
    }

    initialPage: Qt.resolvedUrl("pages/MainPage.qml")
    cover: CoverPage {
        id: coverPage
    }

    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
}


