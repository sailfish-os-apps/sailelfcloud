"""
Created on Dec 23, 2017

@author: Teemu Ahola [teemuahola7@gmail.com]
"""

import fileHelpers
from Crypto.Protocol import KDF

import legacykeyring
import jsonkeyring

keyRingDir = None
(keyringKey, keyringIv) = (None, None)


def _createKeyRingDir(configLocation):
    path = os.path.join(configLocation, 'keys')
    os.makedirs(path, exist_ok=True)
    fileHelpers.setDirAccessRights(path)
    return path

def _generateKeyringEncryptionKey(passwd):
    return KDF.PBKDF2(passwd, "", count=100000), 0

def init(configLocation, passwd):
    global keyRingDir, keyringKey, keyringIv
    keyRingDir = _createKeyRingDir(configLocation)
    (keyringKey, keyringIv) = _generateKeyringEncryptionKey(passwd)

def importLegacyKeyring():
    keyFiles = legacykeyring.findXmlKeyFiles(keyRingDir)

    for keyFile in keyFiles:
        key = legacykeyring.importKeyFromXml(keyFile)
        jsonkeyring.storeKey(key)
