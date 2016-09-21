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

def handle_exception(func):
    from functools import wraps
    @wraps(func)
    def exception_handler(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except elfcloud.exceptions.ECAuthException as e:
            raise ClientException(e.id, e.message) from e
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

