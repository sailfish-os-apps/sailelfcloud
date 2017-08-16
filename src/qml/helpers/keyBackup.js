.pragma library

var _elfCloud = undefined;
var _keyHandler = undefined;
var _stateCb = undefined;
var _passwd = undefined

var CLOUD_KEYRING_1 = "com.ahola.sailelfcloud.keyring.user.1";
var CLOUD_KEYRING_2 = "com.ahola.sailelfcloud.keyring.user.2";
var CLOUD_KEYRING_ACTIVE = "com.ahola.sailelfcloud.keyring.user.active";

/*
  JSON document structure for key backup:

  {
    "timestamp": "<ts>", // local timestamp <ts> when backup was created
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

/// This function converts keyring object to JSON source object (which can be marshalled to JSON)
// Argumenty keyRing object must be type returned by python
// keyhandler.getKeys()
function convertKeyRingObject2JsonObject(keyRingObject) {

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

    return { timestamp: 0, keys: keys };
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
    console.error("Failed to backup keyring:", reasonId, reasonMsg);
    _stateCb("failed");
}

function _gotKeyringContentForVerify(content, expectedKeyringContent) {

    if (content === expectedKeyringContent)
        _stateCb("done");
    else {
        console.error("Failed to backup keyring: content verify failed");
        _stateCb("failed");
    }
}

function _setActiveKeyring(keyring, expectedKeyringContent) {
    _stateCb("verify");
    _elfCloud.getProperty(keyring,
                          function(content) { _gotKeyringContentForVerify(content, expectedKeyringContent); },
                          _failedCb);
}

function _setKeyringContent(keyring, keyringContent) {
    _elfCloud.setProperty(CLOUD_KEYRING_ACTIVE, keyring,
                          function() { _setActiveKeyring(keyring, keyringContent); },
                          _failedCb);
}

function _gotKeyringContent(activeKeyring, keyringContent) {
    var keyInfo = _keyHandler.getKeys();

    if (keyringContent === undefined) {
    } else {
    }

    _stateCb("merge");
    var jsonObject = convertKeyRingObject2JsonObject(keyInfo);
    var jsonString = JSON.stringify(jsonObject);
    console.debug("JSON:", jsonString);


    _stateCb("store");
    var keyring = undefined;

    if (activeKeyring === CLOUD_KEYRING_1) {
        keyring = CLOUD_KEYRING_2;
    } else {
        keyring = CLOUD_KEYRING_1;
    }

    _elfCloud.setProperty(keyring, jsonString,
                          function() { _setKeyringContent(keyring, jsonString); },
                          _failedCb);
}

function _gotActiveKeyring(activeKeyring) {
    console.debug("Currently active keyring is:", activeKeyring);

    if (activeKeyring === undefined) {
        activeKeyring = CLOUD_KEYRING_1;
    }

    _elfCloud.getProperty(activeKeyring,
                          function(content) { _gotKeyringContent(activeKeyring, content); },
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
