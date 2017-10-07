
.pragma library

var _elfCloud = undefined;
var _keyHandler = undefined;
var _stateCb = undefined;
var _passwd = undefined

var KEY_BACKUP_VERSION = "1.0"
var CLOUD_KEYRING_1 = "com.ahola.sailelfcloud.keyring.user.1";
var CLOUD_KEYRING_2 = "com.ahola.sailelfcloud.keyring.user.2";
var CLOUD_KEYRING_ACTIVE = "com.ahola.sailelfcloud.keyring.user.active";


function _init() {
    _elfCloud.setProperty(CLOUD_KEYRING_1, "");
    _elfCloud.setProperty(CLOUD_KEYRING_2, "");
    _elfCloud.setProperty(CLOUD_KEYRING_ACTIVE, "");
}


function PruneKeyringInCloud(elfCloud, keyHandler, stateCb, passwd) {
    _elfCloud = elfCloud;
    _keyHandler = keyHandler;
    _stateCb = stateCb;
    _passwd = passwd
    _init();
}
