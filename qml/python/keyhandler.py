'''
Created on Jun 21, 2016

@author: teemu
'''

import os
import pathlib
import xml.etree.ElementTree as et 
import worker
from os import SEEK_SET

keyStoreDir = None
keyDatabase = {}

def _createKeyStore(configLocation):
    global keyStoreDir
    keyStoreDir = os.path.join(configLocation, 'keys')
    os.makedirs(keyStoreDir, exist_ok=True)

def _checkIfXmlFileIsKeyFile(file):
    tree = et.ElementTree(None, file)
    root = tree.getroot()
    return root.tag == 'ec:key' and \
        'xmlns:ec' in root.attrib and \
        root.attrib['xmlns:ec'] == "https://secure.elfcloud.fi/xml/elfCLOUD" 

def _addKeyFileToDatabase(file):
    tree = et.ElementTree(None, file)
    nameTag = tree.find('ec:ShortName')
    print (nameTag)
    #if nameTag:
    #    keyDatabase[]

def _findKeyFiles():
    xmlFiles = [p for p in pathlib.Path(keyStoreDir).glob('*.xml') if p.is_file()]
    for f in xmlFiles:
        with f.open() as fd:
            if (_checkIfXmlFileIsKeyFile(fd)):
                fd.seek(0, SEEK_SET)
                _addKeyFileToDatabase(fd)
    

def init(configLocation):
    _createKeyStore(configLocation)

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
    tree.write(_createKeyFilePath(name), encoding='utf-8', xml_declaration=True,short_empty_elements=False)
    
