.pragma library

var _elfCloud = undefined;
var _keyHandler = undefined;
var _stateCb = undefined;
var _passwd = undefined;

var _mergeOperations = undefined;

var KEY_BACKUP_VERSION = "1.0"
var CLOUD_KEYRING_1 = "com.ahola.sailelfcloud.keyring.user.1";
var CLOUD_KEYRING_2 = "com.ahola.sailelfcloud.keyring.user.2";
var CLOUD_KEYRING_ACTIVE = "com.ahola.sailelfcloud.keyring.user.active";

/*
  JSON document structure for key backup:

  {
    "version": "x.y",    // version string for key backup JSON document format where x is major and y is minor version number
    "timestamp": "<ts>", // local timestamp <ts> when backup was created
    "keyring": ""        // encrypted base64 encoded keyring JSON string
  }
*/

function createBackupJsonString(keyringJsonString) {

    var jsonObject = {
        "version": KEY_BACKUP_VERSION,
        "timestamp": (new Date()).toUTCString(),
        "keyring": Qt.btoa(keyringJsonString)
    }

    return JSON.stringify(jsonObject);
}

function convertKeyringBackupJsonStringToJsonObject(jsonString) {
    var jsonObject = JSON.parse(jsonString);
    jsonObject["keyring"] = Qt.atob(jsonObject["keyring"]);

    return jsonObject;
}

function _failedCb(reasonId, reasonMsg) {
    console.error("Failed to backup keyring due to:", reasonId, reasonMsg);
    _stateCb("failed");
}

function _setActiveKeyring() {
    _stateCb("done", _mergeOperations);
}

function _gotKeyringBackupInCloudForVerify(content, keyringToActive, expectedKeyringBackupContent) {

    if (content === expectedKeyringBackupContent) {
        console.debug("Activating keyring:", keyringToActive);
        _elfCloud.setProperty(CLOUD_KEYRING_ACTIVE, keyringToActive,
                              _setActiveKeyring, _failedCb);
    }
    else {
        console.error("Failed to backup keyring: content verify failed");
        _stateCb("failed", qsTr("Verification failed. Try again."));
    }
}

function _setKeyringBackupToCloud(keyring, expectedKeyringBackupContent) {
    _stateCb("verify");
    _elfCloud.getProperty(keyring,
                          function(content) { _gotKeyringBackupInCloudForVerify(content, keyring, expectedKeyringBackupContent); },
                          _failedCb);
}

function _isBackupVersionSupported(versionString) {
    return KEY_BACKUP_VERSION === versionString;
}

function _gotKeyringBackupJsonStringInCloud(activeKeyring, cloudJsonString) {
    var cloudKeyringJsonString = undefined;

    if (cloudJsonString !== undefined) {
        var cloudJsonObject = convertKeyringBackupJsonStringToJsonObject(cloudJsonString);
        var cloudBackupVersion = cloudJsonObject["version"];

        if ( ! _isBackupVersionSupported(cloudBackupVersion) ) {
            console.error("Cannot backup. Version of backup in cloud is", cloudBackupVersion,
                          "but application supports", KEY_BACKUP_VERSION);
            _stateCb("failed", qsTr("Backup version %1 in cloud is unsupported.").arg(cloudBackupVersion));
            return;
        }

        cloudKeyringJsonString = cloudJsonObject["keyring"];
    }

    _stateCb("merge");
    var localKeyringJsonString = _keyHandler.getKeysAsJsonString();
    var mergedKeyringJSonString = localKeyringJsonString; // will be overwritted if there is keyring in cloud

    if (cloudKeyringJsonString !== undefined) {
        var result = _keyHandler.mergeJsonKeyrings(cloudKeyringJsonString, localKeyringJsonString);
        mergedKeyringJSonString = result[0];
        _mergeOperations = result[1];
    }

    var backupJsonString = createBackupJsonString(mergedKeyringJSonString);

    _stateCb("store");
    var keyring = undefined;

    if (activeKeyring === CLOUD_KEYRING_1) {
        keyring = CLOUD_KEYRING_2;
    } else {
        keyring = CLOUD_KEYRING_1;
    }

    _elfCloud.setProperty(keyring, backupJsonString,
                          function() { _setKeyringBackupToCloud(keyring, backupJsonString); },
                          _failedCb);
}

function _gotActiveKeyring(activeKeyring) {
    console.debug("Currently active keyring is:", activeKeyring);

    if (activeKeyring === undefined) {
        activeKeyring = CLOUD_KEYRING_1;
    }

    _elfCloud.getProperty(activeKeyring,
                          function(jsonString) { _gotKeyringBackupJsonStringInCloud(activeKeyring, jsonString); },
                          _failedCb);
}

function _init() {
    _stateCb("fetch");
    _elfCloud.getProperty(CLOUD_KEYRING_ACTIVE, _gotActiveKeyring, _failedCb);
}

function BackupKeyringToCloud(elfCloud, keyHandler, stateCb, passwd) {

    console.debug("Backing up keyring to cloud...");

    _elfCloud = elfCloud;
    _keyHandler = keyHandler;
    _stateCb = stateCb;
    _passwd = passwd
    _stateCb("init");
    _init();
}

