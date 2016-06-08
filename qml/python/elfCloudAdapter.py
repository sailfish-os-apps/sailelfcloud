'''
Created on Apr 27, 2016

@author: teemu
'''

import time
import elfcloud
import hexdump

try:
    import pyotherside
except ImportError:
    import sys
    # Allow testing Python backend alone.
    print("PyOtherSide not found, continuing anyway!")
    class pyotherside:
        def atexit(self, *args): pass
        def send(self, *args): pass
    sys.modules["pyotherside"] = pyotherside()

APIKEY = 'swrqwb95d98ou8d'
VALULT_TYPES = [elfcloud.utils.VAULT_TYPE_DEFAULT, 'com.ahola.sailelfcloud']
client = None

def _debug(*text):
    pyotherside.send('log-d', ''.join(text))

def _info(*text):
    pyotherside.send('log-i', ''.join(text))

def _error(*text):
    pyotherside.send('log-e', ''.join(text))


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

def _sendFetchCompletedSignal(parentId, name, localname):
    pyotherside.send('fetch-dataitem-completed', parentId, name, localname)

def fetchDataItem(parentId, name, outputPath, key=None):
    _configEncryption()
    data = client.fetch_data(int(parentId), name)['data']
     
    with open(outputPath, mode='wb') as outputFile:
        for d in data:
            outputFile.write(d)
    time.sleep(2)
    _sendFetchCompletedSignal(parentId, name, outputPath)
    
    return True

def readPlainFile(filename):    
    text = ""

    with open(filename, "r") as f:
        for l in f:
            text += l
                
    return text

def readBinFile(filename):    
    text = ""

    with open(filename, "rb") as f:
        text = hexdump.hexdump(f,result="return")
    
    return text


SUBSCRIPTION_FIELD_MAP = {'id':'Id', 'status':'Status', 'start_date':'Start date',
                          'end_date':'End date', 'storage_quota': 'Quota',
                          'subscription_type':'Subscription type'}

def getSubscriptionInfo():
    info = client.get_subscription_info()
    currentSubscription = info['current_subscription']
    # Create list of dict for easier handling in QML
    out = [{'fieldName':toName, 'fieldValue':str(currentSubscription[fromName])} for fromName, toName in SUBSCRIPTION_FIELD_MAP.items()]
    return out
    
def storeDataItem(parentId, remotename, filename):
    _info("Storing: " + filename + " as " + remotename)
    fileobj = open(filename, "rb")
    _configEncryption()

    
    result = client.store_data(int(parentId),
                               remotename,
                               fileobj)
    
    return result

def _sendStoreStartedSignal(parentId):
    pyotherside.send('store-started', parentId)

def _sendStoreCompletedSignal(parentId):
    pyotherside.send('store-completed', parentId)

def _sendDataItemStoreCompletedSignal(parentId, remotePath, localPath):
    pyotherside.send('store-dataitem-completed', parentId, remotePath, localPath)

def storeDataItems(parentId, localRemotePaths):
    _sendStoreStartedSignal(parentId)
    
    for local,remote in localRemotePaths:
        storeDataItem(parentId, remote, local)
        _sendDataItemStoreCompletedSignal(parentId, remote, local)
        
    _sendStoreCompletedSignal(parentId)
      
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

if __name__ == '__main__':
    pass
