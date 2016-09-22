'''
Created on Sep 17, 2016

@author: @author: Teemu Ahola [teemuahola7@gmail.com]
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

class ClientException(Exception):
    
    def __init__(self, id=0, msg="unknown"):
        self.__id = id
        self.__msg = msg
        
    @property
    def id(self):
        return self.__id

    @property
    def msg(self):
        return self.__msg

class NotConnected(ClientException):
    
    def __init__(self):
        ClientException.__init__(self, 0, "not connected")

class AuthenticationFailure(ClientException):
    pass


def handle_exception(func):
    from functools import wraps
    @wraps(func)
    def exception_handler(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except elfcloud.exceptions.ECAuthException as e:
            raise AuthenticationFailure(e.id, e.message) from e
        except elfcloud.exceptions.ECException as e:
            raise ClientException(e.id, e.message) from e            
        except elfcloud.exceptions.ClientException as e:
            raise ClientException(e.id, e.message) from e
        except NotConnected:
            raise
        except Exception as e:
            raise ClientException(0, str(e)) from e
            
    return exception_handler

def check_connected(func):
    from functools import wraps
    @wraps(func)
    def _check_connection(*args, **kwargs):
        if not isConnected():
            raise NotConnected()
        return func(*args, **kwargs)
    return _check_connection


def setRequestSize(sizeInBytes):
    client.set_request_size(sizeInBytes)

@handle_exception
def connect(username, password):
    global client
    try:
        client = elfcloud.Client(username=username, auth_data=password,
                                 apikey=APIKEY,
                                 server_url=elfcloud.utils.SERVER_DEFAULT)
        client.auth()
        logger.info("elfCLOUD client connected")
        setRequestSize(DEFAULT_REQUEST_SIZE_BYTES)
    except elfcloud.exceptions.ECAuthException: # this we will handle by ourselves
        client = None
        raise   

def isConnected():
    return client != None

def disconnect():
    global client
    client = None
    logger.info("elfCLOUD client disconnected")

def setEncryption(key, iv):
    client.encryption_mode = elfcloud.utils.ENC_AES256
    client.set_encryption_key(binascii.unhexlify(key))
    client.set_iv(binascii.unhexlify(iv))

def clearEncryption():
    client.encryption_mode = elfcloud.utils.ENC_NONE    

SUBSCRIPTION_FIELD_MAP = {'id':'Id', 'status':'Status', 'start_date':'Start date',
                          'end_date':'End date', 'storage_quota': 'Quota',
                          'subscription_type':'Subscription type', 'renewal_type':'Renewal type'}

@handle_exception
@check_connected
def getSubscriptionInfo():
    info = client.get_subscription_info()
    subscr = info['current_subscription']
    return {to_: str(subscr[from_]) for from_,to_ in SUBSCRIPTION_FIELD_MAP.items()}

@handle_exception
@check_connected
def upload(parentId, remotename, filename, chunkCb=None):
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

@handle_exception
@check_connected
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

def listContent(parentId):
    contentList = []   
    clusters, dataitems = client.list_contents(int(parentId))

    for cluster in clusters:
        contentList.append({'name':        cluster.name,
                            'id'  :        cluster.id,
                            'descendants': cluster.descendants,
                            'parentId':    cluster.parent_id,
                            'modified':    cluster.modified_date,
                            'accessed':    cluster.last_accessed_date, 
                            'permissions': cluster.permissions,                            
                            'type':        'cluster'})

    for dataitem in dataitems:
        contentList.append({'name':       dataitem.name,
                            'id'  :       0,
                            'parentId':   dataitem.parent_id,
                            'type':       'dataitem',
                            'tags':       dataitem.meta.get('TGS', ""),
                            'encryption': dataitem.meta.get('ENC', "NONE"),
                            'contentHash':dataitem.meta.get('CHA', ""),
                            'keyHash':    dataitem.meta.get('KHA', "")})
        
    return contentList

