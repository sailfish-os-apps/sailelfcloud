.pragma library

var _elfCloud = undefined;
var _keyHandler = undefined;
var _stateCb = undefined;
var _passwd = undefined

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
function createJsonObjectForKeyBackup(keyringJsonString) {

    var jsonObject = {
        "version": KEY_BACKUP_VERSION,
        "timestamp": (new Date()).toUTCString(),
        "keyring": Qt.btoa(keyringJsonString)
    }

    return JSON.stringify(jsonObject);
}

function convertKeyBackupJsonStringToJsonObject(keyBackupJsonString) {
    var jsonObject = JSON.parse(keyBackupJsonString);
    jsonObject["keyring"] = Qt.atob(jsonObject["keyring"]);

    return jsonObject;
}

/*
  JSON document structure for keyring:

  {
    "timestamp": "<ts>", // local timestamp <ts> when key chain was created
    "keys": [            // array of keys in backup
        "<name>": {      // object for key , where <name> is unique name of a key
            "description": "<descr>",
            "type": "<type>",
            "mode": "<mode>",
            "iv": "<iv>",
            "key": "<key>"
            "hash": "<hash>"
        },
        ...
    ]
  }

*/

/// This function converts keyring object to JSON string (marshalled)
// Argumenty keyRing object must be type returned by python
// keyhandler.getKeys()
function convertKeyRingObject2JsonString(keyRingObject) {

    var keys = []

    for (var i = 0; i < keyRingObject.length; i++) {
        var keyToConvert = keyRingObject[i];
        var keyData = { description: keyToConvert.description,
                        type: keyToConvert.type,
                        mode: keyToConvert.mode,
                        iv: keyToConvert.iv,
                        key: keyToConvert.key,
                        hash: keyToConvert.hash };
        var key = {};
        key[keyToConvert.name] = keyData;
        keys.push(key);
    }

    var jsonObject = { timestamp: (new Date()).toUTCString(), keys: keys };
    return JSON.stringify(jsonObject);
}

function convertJsonObject2KeyRingObject(jsonObject) {
    var keyRing = []
    var ts = jsonObject.timestamp

    for (var i = 0; i < jsonObject.keys.length; i++) {
        var keyToConvert = jsonObject.keys[i];
        var keyData = { description: keyToConvert.description,
                        type: keyToConvert.type,
                        mode: keyToConvert.mode,
                        iv: keyToConvert.iv,
                        key: keyToConvert.key,
                        hash: keyToConvert.hash };
        keyRing.push(keyData);
    }
    return keyRing;
}

function _failedCb(reasonId, reasonMsg) {
    console.error("Failed to backup keyring due to:", reasonId, reasonMsg);
    _stateCb("failed");
}

function _setActiveKeyring() {
    _stateCb("done");
}

function _gotKeyringBackupContentForVerify(content, keyringToActive, expectedKeyringBackupContent) {

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

function _setKeyringBackupContent(keyring, expectedKeyringBackupContent) {
    _stateCb("verify");
    _elfCloud.getProperty(keyring,
                          function(content) { _gotKeyringBackupContentForVerify(content, keyring, expectedKeyringBackupContent); },
                          _failedCb);
}

function _isBackupVersionSupported(versionString) {
    return KEY_BACKUP_VERSION === versionString;
}

function _gotKeyringBackupContent(activeKeyring, keyringBackupContent) {

    if (keyringBackupContent !== undefined) {
        var currentBackupJsonObject = convertKeyBackupJsonStringToJsonObject(keyringBackupContent);
        var backupVersionStringInCloud = currentBackupJsonObject["version"];

        if ( ! _isBackupVersionSupported(backupVersionStringInCloud) ) {
            console.error("Cannot backup. Version of backup in cloud is", backupVersionStringInCloud,
                          "but application supports", KEY_BACKUP_VERSION);
            _stateCb("failed", qsTr("Backup version %1 in cloud is unsupported.").arg(backupVersionStringInCloud));
            return;
        }
    }

    _stateCb("merge");
    var keyInfo = _keyHandler.getKeys();
    var keyringJsonString = convertKeyRingObject2JsonString(keyInfo);
    var backupJsonString = createJsonObjectForKeyBackup(keyringJsonString);

    _stateCb("store");
    var keyring = undefined;

    if (activeKeyring === CLOUD_KEYRING_1) {
        keyring = CLOUD_KEYRING_2;
    } else {
        keyring = CLOUD_KEYRING_1;
    }

    _elfCloud.setProperty(keyring, backupJsonString,
                          function() { _setKeyringBackupContent(keyring, backupJsonString); },
                          _failedCb);
}

function _gotActiveKeyring(activeKeyring) {
    console.debug("Currently active keyring is:", activeKeyring);

    if (activeKeyring === undefined) {
        activeKeyring = CLOUD_KEYRING_1;
    }

    _elfCloud.getProperty(activeKeyring,
                          function(content) { _gotKeyringBackupContent(activeKeyring, content); },
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
