'''
Created on Apr 27, 2016

@author: teemu
'''

import elfcloud
import worker, time

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
MAX_WORKERS = 5
client = None
threadPool = worker.ThreadPool(MAX_WORKERS)

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

def setRequestSize(sizeInBytes):
    client.set_request_size(sizeInBytes)

def listVaults():
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
    return vaultList

def listContent(parentId):
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
    return contentList


def _configEncryption():
    client.set_encryption_key(None)
    client.set_iv(elfcloud.utils.IV_DEFAULT)
    client.encryption_mode = elfcloud.utils.ENC_NONE

def getDataItemInfo(parentId, name):
    dataitem = client.get_dataitem(parentId, name)
    return {'id': dataitem.dataitem_id,
            'name': dataitem.name,
            'size': dataitem.size,
            'description': (dataitem.description if dataitem.description else ''),
            'tags': (dataitem.tags if dataitem.tags else []),
            'accessed': (dataitem.last_accessed_date if dataitem.last_accessed_date else ''),
            'contentHash': (dataitem.content_hash if dataitem.content_hash else ''),
            'keyHash': (dataitem.key_hash if dataitem.key_hash else '')}

def updateDataItem(parentId, name, description=None, tags=None):
    client.update_dataitem(parentId, name, description, tags)

def _sendDataItemChunkFetchedSignal(parentId, name, totalSize, sizeFetched):
    pyotherside.send('fetch-dataitem-chunk', parentId, name, totalSize, sizeFetched)
    
def _sendDataItemFetchedSignal(status, parentId, name, outputPath):
    pyotherside.send('fetch-dataitem-completed', status, parentId, name, outputPath)

def _fetchDataItemCb(parentId, name, outputPath, key=None):
    _configEncryption()
    data = client.fetch_data(int(parentId), name)['data'] 
    dataLength = data.fileobj.getheader('Content-Length') # Nasty way to get total size since what if Content-Length does not exist.
                                                          # I haven't found good way to provide this information in upper level sw.
    dataFetched = 0
    time.sleep(6)
    with open(outputPath, mode='wb') as outputFile:
        for chunk in data:
            outputFile.write(chunk)
            dataFetched += len(chunk)
            _sendDataItemChunkFetchedSignal(parentId, name, dataLength, dataFetched)

    _sendDataItemFetchedSignal(True, parentId, name, outputPath)

def fetchDataItem(parentId, name, outputPath, key=None):
    threadPool.executeTask(_fetchDataItemCb, parentId, name, outputPath, key=None)



SUBSCRIPTION_FIELD_MAP = {'id':'Id', 'status':'Status', 'start_date':'Start date',
                          'end_date':'End date', 'storage_quota': 'Quota',
                          'subscription_type':'Subscription type'}

def _getSubscriptionInfoCb(cbObj):
    try:
        info = client.get_subscription_info()
        subscr = info['current_subscription']
        # Create list of dict for easier handling in QML
        #cbObj.subscription([{'fieldName':toName, 'fieldValue':str(subscr[fromName])} for fromName,toName in SUBSCRIPTION_FIELD_MAP.items()])
        i = [{'fieldName':toName, 'fieldValue':str(subscr[fromName])} for fromName,toName in SUBSCRIPTION_FIELD_MAP.items()]
        #lambda a, b: bound_method(a, b) 
        _sendCompletedSignal(cbObj, i, "asas", 322323)
    except elfcloud.exceptions.ECAuthException as e:
        _sendExceptionSignal(e)

def getSubscriptionInfo(cbObj):
    threadPool.executeTask(_getSubscriptionInfoCb, cbObj)
    return True

def storeDataItem(parentId, remotename, filename):
    _info("Storing: " + filename + " as " + remotename)
    fileobj = open(filename, "rb")
    _configEncryption()

    result = client.store_data(int(parentId),
                               remotename,
                               fileobj)
    return result

def _sendDataItemStoredSignal(status, parentId, remoteName, localName, dataItemsLeft):
    pyotherside.send('store-dataitem-completed', status, parentId, remoteName, localName, dataItemsLeft)

def _sendDataItemsStoredSignal(status, parentId, remoteLocalNames):
    pyotherside.send('store-dataitems-completed', status, parentId, remoteLocalNames)

def _storeDataItemsCb(parentId, remoteLocalNames):
    dataItemsLeft = len(remoteLocalNames)
    
    for remote,local in remoteLocalNames:
        dataItemsLeft -= 1
        storeDataItem(parentId, remote, local)
        _sendDataItemStoredSignal(True, parentId, remote, local, dataItemsLeft)
        
    _sendDataItemsStoredSignal(True, parentId, remoteLocalNames)

def storeDataItems(parentId, remoteLocalNames):
    threadPool.executeTask(_storeDataItemsCb, parentId, remoteLocalNames)

def removeDataItem(parentId, name):
    _info("Removing " + name)
    return client.remove_dataitem(int(parentId), name)

def renameDataItem(parentId, oldName, newName):
    _info("Renaming ", oldName, "to", newName)
    return client.rename_dataitem(int(parentId), oldName, newName)
     
def addVault(name):
    try:
        return client.add_vault(name, VALULT_TYPES[0])
    except elfcloud.exceptions.ECAuthException as e:
        _sendExceptionSignal(e)
        return None

def removeVault(vaultId):
    return client.remove_vault(int(vaultId))

def addCluster(parentId, name):
    return client.add_cluster(name, int(parentId))

def removeCluster(id):
    client.remove_cluster(int(id))

def waitForRunningTasksCompleted():
    threadPool.waitTasksCompletion()

if __name__ == '__main__':
    pass
