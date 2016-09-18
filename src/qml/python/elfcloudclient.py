'''
Created on Sep 17, 2016

@author: teemu
'''

import os
import elfcloud
import worker
import binascii
import logger
import exceptionhandler


APIKEY = 'swrqwb95d98ou8d'
VALULT_TYPES = [elfcloud.utils.VAULT_TYPE_DEFAULT, 'com.ahola.sailelfcloud']
DEFAULT_REQUEST_SIZE_BYTES =  256 * 1024 # Size of one request when sending or fetching
client = None

def setRequestSize(sizeInBytes):
    client.set_request_size(sizeInBytes)

@exceptionhandler.handle_exception
def connect(username, password):
    global client
    try:
        client = elfcloud.Client(username=username, auth_data=password,
                                 apikey=APIKEY,
                                 server_url=elfcloud.utils.SERVER_DEFAULT)
        client.auth()
        logger.info("elfCLOUD client connected")
        setRequestSize(DEFAULT_REQUEST_SIZE_BYTES)
    except:
        client = None
        raise

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
            self.totalReadSize = 0
            
        def read(self, size):
            data = self.fileobj.read(size)
            self.totalReadSize += len(data)
            if len(data) and chunkCb and callable(chunkCb): chunkCb(fileSize, self.totalReadSize)
            return data
    
    with open(filename, "rb") as fileobj:
        fo = _FileObj(fileobj)
        client.store_data(int(parentId), remotename, fo)

