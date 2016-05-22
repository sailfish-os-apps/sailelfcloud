import QtQuick 2.0
import QtQuick.LocalStorage 2.0

Item {

    id: settings

    property var db: null;

    function setup() {
        db = LocalStorage.openDatabaseSync("SailElfCloud", "1.0",
                                           "Setting database for SaifElfCloud",
                                           1024);
    }

    function storeUserName(username) {

    }

}

