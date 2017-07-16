.pragma library

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

var elfCloud = undefined;

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

// Argumenty keysToBackup must be type returned by python
// keyhandler.getKeys()
function BackupKeysToCloud(keysToBackup) {

    var jsonObject = convertKeyRingObject2JsonObject(keysToBackup);
    var orig = convertJsonObject2KeyRingObject(jsonObject);
    var jsonDocument = JSON.stringify(jsonObject);
    console.debug("Backing up keys", jsonDocument);

}
