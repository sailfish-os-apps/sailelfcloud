'''
Created on Apr 27, 2016

@author: teemu
'''

import elfcloud
import worker
import time

try:
    import pyotherside
except ImportError:
    import sys
    # Allow testing Python backend alone.
    print("PyOtherSide not found, continuing anyway!")
    class pyotherside:
        def atexit(self, *args): pass
        def send(self, *args):
            print("send:", [str(a) for a in args])
    sys.modules["pyotherside"] = pyotherside()


APIKEY = 'swrqwb95d98ou8d'
VALULT_TYPES = [elfcloud.utils.VAULT_TYPE_DEFAULT, 'com.ahola.sailelfcloud']
DEFAULT_REQUEST_SIZE_BYTES =  256 * 1024 # Size of one request when sending or fetching
client = None

def _debug(*text):
    pyotherside.send('log-d', ' '.join(text))

def _info(*text):
    pyotherside.send('log-i', ' '.join(text))

def _error(*text):
    pyotherside.send('log-e', ' '.join(text))

def _sendCompletedSignal(cbObj, *args):
    pyotherside.send('completed', cbObj, *args)

def _sendExceptionSignal(exception):
    pyotherside.send('exception', exception.id, exception.message)

def _sendConnectedSignal(status, reason=None):
    pyotherside.send('connected', status, reason)

def connect(username, password):
    global client
    try:
        client = elfcloud.Client(username=username, auth_data=password,
                                 apikey=APIKEY,
                                 server_url=elfcloud.utils.SERVER_DEFAULT)    
        client.auth()
        setRequestSize(DEFAULT_REQUEST_SIZE_BYTES)
    except Exception as e:
        _error(str(e))
        client = None
        _sendConnectedSignal(False, str(e))
        return False

    _info("elfCloud client connected")
    _sendConnectedSignal(True)
    return True

def isConnected():
    return client != None

def disconnect():
    client = None
    _info("elfCloud client disconnected")    
    return True

SUBSCRIPTION_FIELD_MAP = {'id':'Id', 'status':'Status', 'start_date':'Start date',
                          'end_date':'End date', 'storage_quota': 'Quota',
                          'subscription_type':'Subscription type'}

@worker.run_async
def getSubscriptionInfo(cbObj):
    try:
        info = client.get_subscription_info()
        subscr = info['current_subscription']
        # Create list of dict for easier handling in QML
        info = [{'fieldName':toName, 'fieldValue':str(subscr[fromName])} for fromName,toName in SUBSCRIPTION_FIELD_MAP.items()]
        _sendCompletedSignal(cbObj, info)
    except elfcloud.exceptions.ECAuthException as e:
        _sendExceptionSignal(e)

def setRequestSize(sizeInBytes):
    client.set_request_size(sizeInBytes)

@worker.run_async
def listVaults(cbObj):
    vaultList = []
    try:
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
    except elfcloud.exceptions.ECAuthException as e:
        _sendExceptionSignal(e)

    _sendCompletedSignal(cbObj, vaultList)

@worker.run_async
def listContent(cbObj, parentId):
    contentList = []
    _info("Getting content of %s" % parentId)
    
    try:
        clusters, dataitems = client.list_contents(int(parentId))
               
        for cluster in clusters:
            contentList.append({'name':        cluster.name,
                                'id'  :        cluster.id,
                                'dataItems':   cluster.dataitems,
                                'descendants': cluster.descendants,
                                'parentId':    cluster.parent_id,
                                'modified':    cluster.modified_date,
                                'accessed':    cluster.last_accessed_date, 
                                'permissions': cluster.permissions,                            
                                'type':        'cluster'})
    
        for dataitem in dataitems:
            contentList.append({'name':     dataitem.name,
                                'id'  :     0,
                                'size':     dataitem.size,
                                'parentId': dataitem.parent_id,
                                'type':     'dataitem',
                                'metadata': dataitem.meta})
    except elfcloud.exceptions.ECAuthException as e:
        _sendExceptionSignal(e)
        
    _sendCompletedSignal(cbObj, contentList)

def _configEncryption():
    client.set_encryption_key(None)
    client.set_iv(elfcloud.utils.IV_DEFAULT)
    client.encryption_mode = elfcloud.utils.ENC_NONE

@worker.run_async
def getDataItemInfo(cbObj, parentId, name):
    dataitem = client.get_dataitem(parentId, name)
    info = {'id': dataitem.dataitem_id,
            'name': dataitem.name,
            'size': dataitem.size,
            'description': (dataitem.description if dataitem.description else ''),
            'tags': (dataitem.tags if dataitem.tags else []),
            'accessed': (dataitem.last_accessed_date if dataitem.last_accessed_date else ''),
            'contentHash': (dataitem.content_hash if dataitem.content_hash else ''),
            'keyHash': (dataitem.key_hash if dataitem.key_hash else '')}
    _sendCompletedSignal(cbObj, info)

def updateDataItem(parentId, name, description=None, tags=None):
    client.update_dataitem(parentId, name, description, tags)

def _sendDataItemChunkFetchedSignal(parentId, name, totalSize, sizeFetched):
    pyotherside.send('fetch-dataitem-chunk', parentId, name, totalSize, sizeFetched)
    
@worker.run_async
def fetchDataItem(cbObj, parentId, name, outputPath, key=None):
    _configEncryption()
    data = client.fetch_data(int(parentId), name)['data'] 
    dataLength = data.fileobj.getheader('Content-Length') # Nasty way to get total size since what if Content-Length does not exist.
                                                          # I haven't found good way to provide this information in upper level sw.
    dataFetched = 0
    with open(outputPath, mode='wb') as outputFile:
        for chunk in data:
            outputFile.write(chunk)
            dataFetched += len(chunk)
            _sendDataItemChunkFetchedSignal(parentId, name, dataLength, dataFetched)

    _sendCompletedSignal(cbObj, True, parentId, name, outputPath)

@worker.run_async
def storeDataItem(cbObj, parentId, remotename, filename):
    _info("Storing: " + filename + " as " + remotename)
    _configEncryption()
    with open(filename, "rb") as fileobj:        
        client.store_data(int(parentId), remotename, fileobj)
    time.sleep(2)
    _sendCompletedSignal(cbObj, parentId, remotename, filename)

@worker.run_async
def removeDataItem(cbObj, parentId, name):
    _info("Removing " + name) 
    client.remove_dataitem(parentId, name)
    _sendCompletedSignal(cbObj, parentId, name)

@worker.run_async
def renameDataItem(cbObj, parentId, oldName, newName):
    _info("Renaming ", oldName, "to", newName)
    client.rename_dataitem(int(parentId), oldName, newName)
    _sendCompletedSignal(cbObj, parentId, oldName, newName)

@worker.run_async
def addVault(cbObj, name):
    try:
        vaultId = client.add_vault(name, VALULT_TYPES[0])
        _sendCompletedSignal(cbObj, vaultId, name)
        return vaultId
    except elfcloud.exceptions.ECAuthException as e:
        _sendExceptionSignal(e)
        return None

def _addVault(name):
    return client.add_vault(name, VALULT_TYPES[0])

@worker.run_async
def removeVault(cbObj, vaultId):
    client.remove_vault(int(vaultId))
    _sendCompletedSignal(cbObj, vaultId)

@worker.run_async
def addCluster(cbObj, parentId, name):
    client.add_cluster(name, int(parentId))
    _sendCompletedSignal(cbObj, parentId, name)
    
def _addCluster(parentId, name):
    return client.add_cluster(name, int(parentId))

@worker.run_async
def removeCluster(cbObj, clusterId):
    client.remove_cluster(int(clusterId))
    _sendCompletedSignal(cbObj, clusterId)

if __name__ == '__main__':
    pass
