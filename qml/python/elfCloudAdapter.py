'''
Created on Apr 27, 2016

@author: teemu
'''

import elfcloud
import worker

try:
    import pyotherside
except ImportError:
    import sys
    # Allow testing Python backend alone.
    print("PyOtherSide not found, continuing anyway!")
    class pyotherside:
        def atexit(self, *args): pass
        def send(self, *args):
            print("send:", args[0])
    sys.modules["pyotherside"] = pyotherside()


APIKEY = 'swrqwb95d98ou8d'
VALULT_TYPES = [elfcloud.utils.VAULT_TYPE_DEFAULT, 'com.ahola.sailelfcloud']
MAX_WORKERS = 3
client = None
threadPool = worker.ThreadPool(MAX_WORKERS)

def _debug(*text):
    pyotherside.send('log-d', ' '.join(text))

def _info(*text):
    pyotherside.send('log-i', ' '.join(text))

def _error(*text):
    pyotherside.send('log-e', ' '.join(text))


def _sendConnectedSignal(status, reason=None):
    pyotherside.send('connected', status, reason)

def connect(username, password):
    global client
    try:
        client = elfcloud.Client(username=username, auth_data=password,
                                 apikey=APIKEY,
                                 server_url=elfcloud.utils.SERVER_DEFAULT)    
        client.auth()
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
    global client
    client = None
    _info("elfCloud client disconnected")
    return True

def listVaults():
    vaults = client.list_vaults()
    vaultList = []   
           
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
    parentId = int(parentId)
    _info("Getting content of %s" % parentId)
    
    clusters, dataitems = client.list_contents(parentId)
    contentList = []
           
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

def _sendDataItemFetchedSignal(status, parentId, name, outputPath):
    pyotherside.send('fetch-dataitem-completed', status, parentId, name, outputPath)

def _fetchDataItemCb(parentId, name, outputPath, key=None):
    _configEncryption()
    data = client.fetch_data(int(parentId), name)['data']
     
    with open(outputPath, mode='wb') as outputFile:
        for d in data:
            outputFile.write(d)

    _sendDataItemFetchedSignal(True, parentId, name, outputPath)

def fetchDataItem(parentId, name, outputPath, key=None):
    threadPool.executeTask(_fetchDataItemCb, parentId, name, outputPath, key=None)



SUBSCRIPTION_FIELD_MAP = {'id':'Id', 'status':'Status', 'start_date':'Start date',
                          'end_date':'End date', 'storage_quota': 'Quota',
                          'subscription_type':'Subscription type'}

def _getSubscriptionInfoCb(workData):
    info = client.get_subscription_info()
    currentSubscription = info['current_subscription']
    # Create list of dict for easier handling in QML
    workData.setData([{'fieldName':toName, 'fieldValue':str(currentSubscription[fromName])} for fromName,
                      toName in SUBSCRIPTION_FIELD_MAP.items()])

def getSubscriptionInfo():
    response = worker.WorkData()
    threadPool.executeTask(_getSubscriptionInfoCb, response)
    return response.waitForData()

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
    return client.add_vault(name, VALULT_TYPES[0])

def removeVault(id):
    return client.remove_vault(int(id))

def addCluster(parentId, name):
    return client.add_cluster(name, int(parentId))

def removeCluster(id):
    client.remove_cluster(int(id))

def waitForRunningTasksCompleted():
    threadPool.waitTasksCompletion()

if __name__ == '__main__':
    pass
