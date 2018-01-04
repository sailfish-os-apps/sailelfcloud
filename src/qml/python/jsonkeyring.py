"""
Created on Dec 22, 2017

@author: Teemu Ahola [teemuahola7@gmail.com]

JSON document structure for keyring:
  {
    "keys": {            // object for keys in backup, every key is a member of this object
        "<name>": {      // object for key , where <name> is unique name of a key
            "description": "<descr>",
            "timestamp": "<ts>",
            "type": "<type>",
            "mode": "<mode>",
            "iv": "<iv>",
            "key": "<key>"    // actual key encrypted with AES256
            "hash": "<hash>"
        },
        ...
    }
  }
"""

import json
from Crypto.Cipher import AES


def convertKeyring2Json(keyring):

    keys = {}

    for keyToConvert in keyring:
        keyData = {
            "description": keyToConvert["description"],
            "timestamp": keyToConvert["timestamp"],
            "type": keyToConvert["type"],
            "mode": keyToConvert["mode"],
            "iv": keyToConvert["iv"],
            "key": keyToConvert["key"],
            "hash": keyToConvert["hash"]
        }
        keys[keyToConvert["name"]] = keyData

    jsonObject = {"keys": keys}

    return json.dumps(jsonObject)


def convertJson2Key(jsonDocument):
    keyInfo = []
    jsonObject = json.loads(jsonDocument)
    keys = jsonObject["keys"]

    for keyName, keyData in keys.items():
        key = {"name": keyName,
               "description": keyData["description"],
               "type": keyData["type"],
               "mode": keyData["mode"],
               "iv": keyData["iv"],
               "key": keyData["key"],
               "hash": keyData["hash"]}
        keyInfo.append(key)

    return keyInfo

def storeKey(keyToStore, encryptionKey):
    pass