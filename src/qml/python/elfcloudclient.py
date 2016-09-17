'''
Created on Sep 17, 2016

@author: teemu
'''

import os
import elfcloud
import worker
import binascii
import logger


APIKEY = 'swrqwb95d98ou8d'
VALULT_TYPES = [elfcloud.utils.VAULT_TYPE_DEFAULT, 'com.ahola.sailelfcloud']
DEFAULT_REQUEST_SIZE_BYTES =  256 * 1024 # Size of one request when sending or fetching
client = None

def setRequestSize(sizeInBytes):
    client.set_request_size(sizeInBytes)

def connect(username, password):
    global client
    try:
        client = elfcloud.Client(username=username, auth_data=password,
                                 apikey=APIKEY,
                                 server_url=elfcloud.utils.SERVER_DEFAULT)
        print(client)    
        client.auth()
        logger.info("elfCLOUD client connected")
        setRequestSize(DEFAULT_REQUEST_SIZE_BYTES)
    except elfcloud.exceptions.ECAuthException as e:
        logger.error(str(e))
        client = None
        raise # let caller do rest

def isConnected():
    return client != None

def disconnect():
    global client
    client = None
    logger.info("elfCLOUD client disconnected")    


def upload(parentId, remotename, filename, chunkCb):
    fileSize = os.path.getsize(filename)
    
    class _FileObj(object):
        def __init__(self, fileobj):
            self.fileobj = fileobj
            self.readSize = 0
            
        def read(self, size):
            data = self.fileobj.read(size)
            self.readSize += len(data)
            if chunkCb and callable(chunkCb): chunkCb(fileSize, self.readSize)
            return data
    
    with open(filename, "rb") as fileobj:
        fo = _FileObj(fileobj)     
        client.store_data(int(parentId), remotename, fo)

