'''
Created on Aug 22, 2016

@author: teemu
'''

import threading
import queue
import tasks

def atomic(func):
    from functools import wraps
    @wraps(func)
    def _atomically(self, *args, **kwargs):
        with self.lock:
            return func(self, *args, **kwargs)
    return _atomically

class UidGenerator(object):
    
    def __init__(self, value=0):
        self.lock = threading.Lock()
        self.value = value
    
    @atomic
    def get(self):
        self.value += 1
        return self.value

class XferThread(threading.Thread):

    def __init__(self):
        super(XferThread, self).__init__(daemon=True)        
        self.uidGenerator = UidGenerator()
        self.downloadManager = DownloadManager()
        self.tasks = queue.Queue()
        self.start()
        self.running = True

    def _handleUploadTask(self, task):
        pass
    
    def _handleXferTask(self, task):
        self.downloadManager.submitTask(task)

    def run(self):
        while self.running:
            task = self.tasks.get() # blocks until work to do
            
            if isinstance(task, task.XferTask):
                self._handleXferTask(task)
            
            self.tasks.task_done()

    def submitTask(self, task):
        task.uid = self.uidGenerator.get()
        self.tasks.put_nowait(task)
        return task.uid

    def waitAllDone(self):
        pass
            
XFER_WORKER = XferThread()

def submitTask(task):
    return XFER_WORKER.submitTask(task)

def download(localPath, remoteParentId, remoteName, key=None, cb=None):
    return XFER_WORKER.submitTask(task.DownloadTask.Create(localPath, remoteParentId, remoteName, key, cb))

def upload(localPath, remoteParentId, remoteName, key=None, cb=None):
    return XFER_WORKER.submitTask(task.UploadTask.Create(localPath, remoteParentId, remoteName, key, cb))

def cancelUpload(uid, cb=None):
    return XFER_WORKER.submitTask(CancelUploadTask.Create(uid, cb))

def cancelDownload(uid, cb=None):
    return XFER_WORKER.submitTask(CancelDownloadTask.Create(uid, cb))

def renameDataItem(remoteParentId, remoteName, newName, cb=None):
    pass

def renameContainer(remoteId, newName, cb=None):
    pass

def addVault(remoteParentId, name, cb=None):
    pass

def removeVault(remoteId, cb=None):
    pass

def addCluster(remoteParentId, name, cb=None):
    pass

def removeCluster(remoteId, cb=None):
    pass

def getDataItemInfo(remoteParentId, remoteName, cb=None):
    pass

def setDataItemInfo(remoteParentId, remoteName, description, tags, cb=None):
    pass

def listContent(remoteParentId, cb=None):
    pass

def listVaults(cb=None):
    pass

def getSubscriptionInfo(cb=None):
    pass

def waitAllDone():
    XFER_WORKER.waitAllDone()
    

