"""
Created on Dec 22, 2017

@author: Teemu Ahola [teemuahola7@gmail.com]
"""

import os
import pathlib
import xml.etree.ElementTree as et
import fileHelpers

def _checkIfXmlFileIsKeyFile(file):
    tree = et.ElementTree(None, file)
    root = tree.getroot()
    return root.tag == '{https://secure.elfcloud.fi/xml/elfCLOUD}key'

def findXmlKeyFiles(path):
    keyFiles = []
    xmlFiles = [p for p in pathlib.Path(path).glob('*.xml') if p.is_file()]
    for f in xmlFiles:
        with f.open(encoding='utf-8') as fd:
            if _checkIfXmlFileIsKeyFile(fd):
                keyFiles.append(f.resolve().as_posix())

    return keyFiles

def _createKeyFilePath():
    path = fileHelpers.uniqueFile(keyStoreDir + os.sep + "key.xml")
    fileHelpers.setFileAccessRights(path)
    return path

def _buildKeyXmlTree(name, description, key, iv, hash, mode, type):
    root = et.Element('ec:key', {'xmlns:ec': 'https://secure.elfcloud.fi/xml/elfCLOUD'})
    et.SubElement(root, 'ec:ShortName').text = name
    et.SubElement(root, 'ec:Description').text = description
    et.SubElement(root, 'ec:Data', {'encoding': 'hexstring'}).text = key
    et.SubElement(root, 'ec:Hash', {'encoding': 'hexstring'}).text = hash

    cipher = et.SubElement(root, 'ec:Cipher')
    et.SubElement(cipher, 'ec:InitializationVector', {'encoding': 'hexstring'}).text = iv
    et.SubElement(cipher, 'ec:Mode').text = mode
    et.SubElement(cipher, 'ec:Type').text = type

    return et.ElementTree(root)

def exportKeyToXml(key, outputDir):
    path = fileHelpers.uniqueFile(outputDir + os.sep + "exported_key.xml")
    fileHelpers.setFileAccessRights(outputPath)
    tree = _buildKeyXmlTree(key['name'], key['description'], key['key'], key['iv'], key['hash'], key['mode'], key['type'])
    tree.write(path, encoding='utf-8', xml_declaration=True,short_empty_elements=False)
    return path

def _readKeyInfoFromFile(file):
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

    return {'name': name, 'description': descr, 'key': data, 'iv': iv,
            'hash': hash, 'mode': mode, 'type': type, 'file': file}

def importKeyFromXml(inputPath):
    return _readKeyInfoFromFile(inputPath)