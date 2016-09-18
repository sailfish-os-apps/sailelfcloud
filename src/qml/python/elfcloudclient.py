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

def check_connected(func):
    from functools import wraps
    @wraps(func)
    def _check_connection(*args, **kwargs):
        if not isConnected():
            raise exceptionhandler.NotConnected()
        return func(*args, **kwargs)
    return _check_connection


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


SUBSCRIPTION_FIELD_MAP = {'id':'Id', 'status':'Status', 'start_date':'Start date',
                          'end_date':'End date', 'storage_quota': 'Quota',
                          'subscription_type':'Subscription type', 'renewal_type':'Renewal type'}
@check_connected
@exceptionhandler.handle_exception
def getSubscriptionInfo():
    info = client.get_subscription_info()
    subscr = info['current_subscription']
    return {to_: str(subscr[from_]) for from_,to_ in SUBSCRIPTION_FIELD_MAP.items()}

@check_connected
@exceptionhandler.handle_exception
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

@check_connected
@exceptionhandler.handle_exception
def listVaults():
    vaultList = []
    vaults = client.list_vaults()   
       
    for vault in vaults:
        vaultList.append({'name': vault.name,
                          'id': vault.id,
                          'size': 0,
                          'type': 'vault',
                          'vaultType': vault.vault_type,
                          'permissions': vault.permissions,
                          'modified': vault.modified_date,
                          'accessed': vault.last_accessed_date,
                          'ownerFirstName': vault.owner['firstname'],
                          'ownerLastName': vault.owner['lastname']})
    return vaultList

