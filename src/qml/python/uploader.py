'''
Created on Sep 15, 2016

@author: teemu
'''

import threading
import elfCloudAdapter
import queue
from collections import deque
import tasks
import worker

class UploadTask(tasks.XferTask):
    
    @classmethod
    def Create(cls, localPath, remoteParentId, remoteName, key=None, cb=None):
        return cls(cb, localPath, remoteParentId, remoteName, key)
    
    def __init__(self, cb, localPath, remoteParentId, remoteName, key):
        super().__init__(cb)
        self.localPath = localPath
        self.remoteParentId = remoteParentId
        self.remoteName = remoteName
        self.key = key
        
class UploadCompletedTask(UploadTask):
    
    @classmethod
    def Create(cls, task):
        return cls(task.cb, task.localPath, task.remoteParentId, task.remoteName, task.key)

class CancelUploadTask(tasks.CancelTask):

    @classmethod
    def Create(cls, uidToCancel, cb):
        return cls(uidToCancel, cb)
    
    def __init__(self, uidToCancel, cb):
        super().__init__(uidToCancel, cb)

class Uploader(threading.Thread):
    
    def __init__(self, queue):
        super(Uploader, self).__init__(daemon=True)
        self.queue = queue
        self.running = True
        self.start()
        
    def run(self):
        while self.running:
            task = self.queue.get()
            
            if isinstance(task, UploadTask):
                print("uploading", task.uid, task.localPath, task.remoteParentId, task.remoteName, task.key)
                elfCloudAdapter.storeDataItem(task.cb, task.remoteParentId, task.remoteName, task.localPath)
            elif isinstance(task, tasks.TerminateTask):
                self.running = False
             
            self.queue.task_done()


class UploadManager(threading.Thread):
    
    def __init__(self):
        super(UploadManager, self).__init__(daemon=True)
        self.running = True        
        self.commandQueue = queue.Queue()
        self.submitQueue = queue.Queue(1)
        self.todoQueue = deque()
        self.uploader = Uploader(self.submitQueue)
        self.start()
    
    def waitUntilCompleted(self):
        self.commandQueue.join()
    
    def submitTask(self, task):
        self.commandQueue.put(task)
        return task.uid
   
    def _submitTodoTaskToDownloader(self):
        if len(self.todoQueue):
            self.submitQueue.put(self.todoQueue.popleft())

    def _handleUploadTask(self, task):
        self.todoQueue.append(task)
        self._submitTodoTaskToDownloader()

    def _handleUploadCompletedTask(self, task):
        self.tasks.task_done()
        self._submitTodoTaskToDownloader()

    def _handleCancelTask(self, task):
        self.tasks.task_done()
    
    def _submitTerminateTaskToUploader(self):
        try:
            self.submitQueue.put(tasks.TerminateTask(), timeout=1)
        except queue.Full:
            print("takes too long to terminate uploader")
            return
        
        self.submitQueue.join()
    
    def _handleTerminateTask(self, task):
        self.running = False
        self._submitTerminateTaskToUploader()
        self.tasks.task_done()
        self.uploader.join(1.5)
    
    def run(self):
        while self.running:
            task = self.commandQueue.get() # blocks until work to do
            
            if isinstance(task, UploadTask):
                self._handleUploadTask(task)
            elif isinstance(task, tasks.CancelTask):
                self._handleCancelTask(task)
            elif isinstance(task, UploadCompletedTask):
                self._handleUploadCompletedTask(task)
            elif isinstance(task, tasks.TerminateTask):
                self._handleTerminateTask()
                        
UPLOADER = UploadManager()

def upload(localPath, remoteParentId, remoteName, key=None, cb=None):
    return UPLOADER.submitTask(UploadTask.Create(localPath, remoteParentId, remoteName, key, cb))

def cancel(uid, cb):
    UPLOADER.submitTask(CancelUploadTask.Create(uid, cb))

def terminate():
    UPLOADER.submitTask(tasks.TerminateTask())
    UPLOADER.waitUntilCompleted()
    
    
