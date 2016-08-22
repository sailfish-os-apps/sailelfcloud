'''
Created on Jul 19, 2016

@author: teemu
'''

import elfCloudAdapter
import threading
import queue
from collections import deque

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

class Task(object):
    
    def __init__(self, cb):
        self.uid = None
        self.cb = cb

class UploadTask(object):
    
    @classmethod
    def Create(cls, localPath, remoteParentId, remoteName, key=None, cbObj=None):
        return cls(cbObj, localPath, remoteParentId, remoteName, key)
    
    def __init__(self, cbObj, localPath, remoteParentId, remoteName, key):
        self.uid = None
        self.cbObj = cbObj
        self.localPath = localPath
        self.remoteParentId = remoteParentId
        self.remoteName = remoteName
        self.key = key

class DownloadTask(object):

    @classmethod
    def Create(cls, localPath, remoteParentId, remoteName, key=None, cbObj=None):
        return cls(cbObj, localPath, remoteParentId, remoteName, key)
    
    def __init__(self, cbObj, remoteName, remoteParentId, localPath, key):
        self.uid = None
        self.cbObj = cbObj
        self.remoteName = remoteName
        self.remoteParentId = remoteParentId
        self.localPath = localPath
        self.key = key

class DownloadCompletedTask(DownloadTask):
    
    @classmethod
    def Create(cls, task):
        return cls(task.cbObj, task.localPath, task.remoteParentId, task.remoteName, task.key)

 
class WaitCompletionTask(object):

    def __init__(self):
        self.uid = None     
    
class CancelTask(Task):

    def __init__(self, uidToCancel, cb):
        super().__init__(cb)
        self.uidOfTaskToCancel = uidToCancel  

class CancelDownloadTask(CancelTask):

    @classmethod
    def Create(cls, uidToCancel, cb):
        return cls(uidToCancel, cb)
    
    def __init__(self, uidToCancel, cb):
        super().__init__(uidToCancel, cb)

class CancelUploadTask(CancelTask):

    @classmethod
    def Create(cls, uidToCancel, cb):
        return cls(uidToCancel, cb)
    
    def __init__(self, uidToCancel, cb):
        super().__init__(uidToCancel, cb)

    
class XferQueue(object):
    
    def __init__(self):
        self.queue = queue.Queue()
        
    def push(self, task):
        self.queue.put(task)

    def pop(self):
        task = self.queue.get()
        return task
    
    def completed(self):
        self.queue.task_done()        
    
    def prune(self):
        tasks = {}
        task = self.queue.get_nowait()
        
        while task:
            tasks[task.uid] = task
            self.queue.task_done()
            try:
                task = self.queue.get_nowait()
            except queue.Empty:
                task = None
            
        return tasks
    
    def removeSpecific(self, uid):
        tasks = self.prune()
        tasks.pop(uid, None)
        
        for task in tasks.values():
            self.push(task)
    
    def waitUntilEmpty(self):
        self.queue.join()

class Uploader(threading.Thread):
    
    def __init__(self, queue):
        super(Uploader, self).__init__(daemon=True)
        self.queue = queue
        self.start()
        
    def run(self):
        while True:
            task = self.queue.pop()
            print("uploading", task.uid, task.localPath, task.remoteParentId, task.remoteName, task.key)
            elfCloudAdapter.storeDataItem(task.cbObj, task.remoteParentId, task.remoteName, task.localPath)
            self.queue.completed()

class Downloader(threading.Thread):
    
    def __init__(self, submitQueue, completedQueue):
        super(Downloader, self).__init__(daemon=True)
        self.submitQueue = submitQueue
        self.completedQueue = completedQueue
        self.start()
        
    def run(self):
        while True:
            task = self.submitQueue.pop()
            print("downloading", task.uid, task.remoteName, task.remoteParentId, task.localPath, task.key)
            elfCloudAdapter.fetchDataItem(task.cbObj, task.remoteParentId, task.remoteName, task.localPath, task.key)
            self.submitQueue.completed()
            self.completedQueue.put(DownloadCompletedTask.Create(task))          

class DownloadManager(threading.Thread):
    
    def __init__(self):
        super(DownloadManager, self).__init__(daemon=True)        
        self.commandQueue = queue.Queue()
        self.submitQueue = queue.Queue(1)
        self.todoQueue = deque()
        self.downloader = Downloader(self.submitQueue)
        self.start()
    
    def waitUntilCompleted(self):
        pass
    
    def submitDownload(self, task):
        self.commandQueue.put(task)
   
    def submitCancel(self, task):
        self.commandQueue.put(task)

    def _submitTodoTaskToDownloader(self):
        if len(self.todoQueue):
            self.submitQueue.put(self.todoQueue.popleft())

    def _handleDownloadTask(self, task):
        self.todoQueue.append(task)
        self._submitTodoTaskToDownloader()

    def _handleDownloadCompletedTask(self, task):
        self._submitTodoTaskToDownloader()

    def _handleCancelTask(self, task):
        pass
    
    def run(self):
        while True:
            task = self.commandQueue.get() # blocks until work to do
            
            if isinstance(task, DownloadTask):
                self._handleDownloadTask(task)
            elif isinstance(task, CancelTask):
                self._handleCancelTask(task)
            elif isinstance(task, DownloadCompletedTask):
                self._handleDownloadCompletedTask(task)
            
            self.tasks.task_done()


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
    
    def _handleDownloadTask(self, task):
        self.downloadManager.submitDownload(task)

    def _handleWaitCompletionTask(self, task):
        self.running = False
        
    def _handleCancelTask(self, task):
        pass

    def run(self):
        while self.running:
            task = self.tasks.get() # blocks until work to do
            
            if isinstance(task, UploadTask):
                self._handleUploadTask(task)
            elif isinstance(task, DownloadTask):
                self._handleDownloadTask(task)
            elif isinstance(task, WaitCompletionTask):
                self._handleWaitCompletionTask(task)
            elif isinstance(task, CancelTask):
                self._handleCancelTask(task)
            
            self.tasks.task_done()

    def submitTask(self, task):
        task.uid = self.uidGenerator.get()
        self.tasks.put_nowait(task)
        return task.uid

    def waitAllDone(self):
        self.submitTask(WaitCompletionTask())
        self.tasks.join()
        
XFER_WORKER = XferThread()

def submitTask(task):
    return XFER_WORKER.submitTask(task)

def download(localPath, remoteParentId, remoteName, key=None, cb=None):
    return XFER_WORKER.submitTask(DownloadTask.Create(localPath, remoteParentId, remoteName, key, cb))

def upload(localPath, remoteParentId, remoteName, key=None, cb=None):
    return XFER_WORKER.submitTask(UploadTask.Create(localPath, remoteParentId, remoteName, key, cb))

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
    
