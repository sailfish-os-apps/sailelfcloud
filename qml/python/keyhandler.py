'''
Created on Jun 21, 2016

@author: teemu
'''

import os
import pathlib
import xml.etree.ElementTree as et 
import worker

keyStoreDir = None
keyDatabase = {}

def _checkIfXmlFileIsKeyFile(file):
    tree = et.ElementTree(None, file)
    root = tree.getroot()
    return root.tag == '{https://secure.elfcloud.fi/xml/elfCLOUD}key' 

def _addKeyFileToDatabase(file):
    tree = et.ElementTree(None, file)
    hash = tree.findtext('{https://secure.elfcloud.fi/xml/elfCLOUD}Hash')

    if hash not in keyDatabase:
        keyDatabase[hash] = file

def findKeyFiles(path):
    keyFiles = []
    xmlFiles = [p for p in pathlib.Path(path).glob('*.xml') if p.is_file()]
    for f in xmlFiles:
        with f.open() as fd:
            if (_checkIfXmlFileIsKeyFile(fd)):
                keyFiles.append(f.resolve().as_posix())
    
    return keyFiles

def _findAndAddKeyFiles(path):
    keyFiles = findKeyFiles(path)
    for k in keyFiles:
        _addKeyFileToDatabase(k)

def _createKeyStore(configLocation):
    global keyStoreDir
    keyStoreDir = os.path.join(configLocation, 'keys')
    os.makedirs(keyStoreDir, exist_ok=True)
    _findAndAddKeyFiles(keyStoreDir)

def init(configLocation):
    _createKeyStore(configLocation)

def readKeyInfoFromFile(file):
    
    if not file:
        return None
    
    tree = et.ElementTree(None, file)
    
    name = tree.findtext('{https://secure.elfcloud.fi/xml/elfCLOUD}ShortName')
    descr = tree.findtext('{https://secure.elfcloud.fi/xml/elfCLOUD}Description')
    data = tree.findtext('{https://secure.elfcloud.fi/xml/elfCLOUD}Data')
    hash = tree.findtext('{https://secure.elfcloud.fi/xml/elfCLOUD}Hash')
    
    cipher = tree.find('{https://secure.elfcloud.fi/xml/elfCLOUD}Cipher')
    iv = cipher.findtext('{https://secure.elfcloud.fi/xml/elfCLOUD}InitializationVector')
    mode = cipher.findtext('{https://secure.elfcloud.fi/xml/elfCLOUD}Mode')
    type = cipher.findtext('{https://secure.elfcloud.fi/xml/elfCLOUD}Type')
    
    return {'name':name, 'description':descr, 'data':data, 'iv':iv,
            'hash':hash, 'mode':mode, 'type':type}

def getKey(hash):
    return readKeyInfoFromFile(keyDatabase.get(hash, None))

def isKey(hash):
    return keyDatabase.get(hash, None) != None

def getKeys():
    keys = []
    
    for _key, file in keyDatabase.items():
        keys.append(readKeyInfoFromFile(file))
    
    return keys

def _buildKeyXmlTree(name, description, key, iv, hash, mode, type):
    root = et.Element('ec:key', {'xmlns:ec': 'https://secure.elfcloud.fi/xml/elfCLOUD'})
    et.SubElement(root, 'ec:ShortName').text=name
    et.SubElement(root, 'ec:Description').text=description
    et.SubElement(root, 'ec:Data', {'encoding':'hexstring'}).text=key
    et.SubElement(root, 'ec:Hash', {'encoding':'hexstring'}).text=hash
    
    cipher = et.SubElement(root, 'ec:Cipher')
    et.SubElement(cipher, 'ec:InitializationVector', {'encoding':'hexstring'}).text=iv
    et.SubElement(cipher, 'ec:Mode').text=mode
    et.SubElement(cipher, 'ec:Type').text=type
    
    return et.ElementTree(root)
    
def _createKeyFilePath(keyName):
    return keyStoreDir + os.sep + keyName + os.extsep + "xml"   

def storeKey(name, description, key, iv, hash, mode='CFB8', type='AES128'):
    tree = _buildKeyXmlTree(name, description, key, iv, hash, mode, type)
    keyFilePath = _createKeyFilePath(name)
    tree.write(keyFilePath, encoding='utf-8', xml_declaration=True,short_empty_elements=False)
    _addKeyFileToDatabase(keyFilePath)
    
def removeKey(hash):
    keyFile = keyDatabase.get(hash, None)
    
    if keyFile:
        os.remove(keyFile)
        keyDatabase.pop(hash)
        return True
    
    return False
