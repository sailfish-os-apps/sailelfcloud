'''
Created on Jul 19, 2016

@author: teemu
'''

import elfCloudAdapter
import threading
import queue
import time

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
    
class WaitCompletionTask(object):

    def __init__(self):
        self.uid = None     
    
class CancelTask(object):

    def __init__(self, uid):
        self.uid = None
        self.uidOfTaskToCancel = uid  
    
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
    
    def __init__(self, queue):
        super(Downloader, self).__init__(daemon=True)
        self.queue = queue
        self.start()
        
    def run(self):
        while True:
            task = self.queue.pop()
            print("downloading", task.uid, task.remoteName, task.remoteParentId, task.localPath, task.key)
            elfCloudAdapter.fetchDataItem(task.cbObj, task.remoteParentId, task.remoteName, task.localPath, task.key)
            self.queue.completed()


class XferThread(threading.Thread):

    def __init__(self):
        super(XferThread, self).__init__(daemon=True)        
        self.uidGenerator = UidGenerator()
        self.uploads = XferQueue()
        self.downloads = XferQueue()
        self.uploader = Uploader(self.uploads)
        self.downloader = Downloader(self.downloads)
        self.tasks = queue.Queue()
        self.start()

    def _handleUploadTask(self, task):
        self.uploads.push(task)
    
    def _handleDownloadTask(self, task):
        self.downloads.push(task)

    def _handleWaitCompletionTask(self, task):
        self.downloads.waitUntilEmpty()
        self.uploads.waitUntilEmpty()
        
    def _handleCancelTask(self, task):
        self.uploads.removeSpecific(task.uid)
        self.downloads.removeSpecific(task.uid)

    def run(self):
        while True:
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

    def cancelTask(self, uid):
        self.submitTask(CancelTask(uid))

    def waitAllDone(self):
        self.submitTask(WaitCompletionTask())
        self.tasks.join()
        
XFER_WORKER = XferThread()

def submitTask(task):
    return XFER_WORKER.submitTask(task)

def submitDownload(localPath, remoteParentId, remoteName, key=None, cbObj=None):
    return XFER_WORKER.submitTask(DownloadTask.Create(localPath, remoteParentId, remoteName, key, cbObj))

def submitUpload(localPath, remoteParentId, remoteName, key=None, cbObj=None):
    return XFER_WORKER.submitTask(UploadTask.Create(localPath, remoteParentId, remoteName, key, cbObj))

def cancel(uid):
    XFER_WORKER.cancelTask(uid)

def waitAllDone():
    XFER_WORKER.waitAllDone()
    
