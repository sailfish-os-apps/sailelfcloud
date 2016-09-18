'''
Created on Sep 15, 2016

@author: teemu
'''

import threading
import elfcloudclient
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
        
    def __str__(self):
        return "UploadTask: %i, %s, %s, %s, %s" % (self.uid, self.localPath, self.remoteParentId, self.remoteName, self.key)
        
class UploadCompletedTask(UploadTask):
    
    @classmethod
    def Create(cls, task):
        return cls(task.cb, task.localPath, task.remoteParentId, task.remoteName, task.key)

    def __str__(self):
        return "UploadCompletedTask: %i" % (self.uid)

class CancelUploadTask(tasks.CancelTask):

    @classmethod
    def Create(cls, uidToCancel, cb):
        return cls(uidToCancel, cb)
    
    def __init__(self, uidToCancel, cb):
        super().__init__(uidToCancel, cb)
        
    def __str__(self):
        return "CancelTask: %i" % (self.uidOfTaskToCancel)

class Uploader(threading.Thread):
    
    def __init__(self, commandQueue, responseQueue):
        super(Uploader, self).__init__(daemon=True)
        self.commandQueue = commandQueue
        self.responseQueue = responseQueue
        self.idle = threading.Event()
        self.running = True
        self.idle.set()
        self.start()

    def isIdling(self):
        return self.idle.isSet()

    def _submitUploadTaskDone(self, task):
        self.responseQueue.put(UploadCompletedTask.Create(task))

    def _handleUploadTask(self, task):
        elfcloudclient.upload(task.remoteParentId, task.remoteName, task.localPath)
        self._submitUploadTaskDone(task)

    def _setBusy(self):
        self.idle.clear()

    def _setIdle(self):
        self.idle.set()

    def run(self):
        while self.running:
            task = self.commandQueue.get()
            self._setBusy()
            
            if type(task) == UploadTask:
                self._handleUploadTask(task)
            elif type(task) == tasks.TerminateTask:
                self.running = False
             
            self._setIdle()
            self.commandQueue.task_done()


class UploadManager(threading.Thread):
    
    def __init__(self):
        super(UploadManager, self).__init__(daemon=True)
        self.running = True
        self.idle = threading.Event()
        self.commandQueue = queue.Queue()
        self.submitQueue = queue.Queue(1)
        self.todoQueue = deque()
        self.uploader = Uploader(self.submitQueue, self.commandQueue)
        self.idle.set()
        self.start()
    
    def waitUntilTasksDone(self):
        self.commandQueue.join()
        self.idle.wait()

    def waitUntilTerminated(self):
        self.commandQueue.join()
        self.submitQueue.join()
    
    def submitTask(self, task):
        self.commandQueue.put(task)
        return task.uid
   
    def _submitTodoTaskToDownloader(self):
        if len(self.todoQueue) and self.submitQueue.unfinished_tasks == 0:
            self.submitQueue.put(self.todoQueue.popleft())

    def _handleUploadTask(self, task):
        self.todoQueue.append(task)
        self._submitTodoTaskToDownloader()

    def _callCb(self, task):
        if callable(task.cb):
            task.cb()

    def _handleUploadCompletedTask(self, task):
        self._callCb(task)
        self._submitTodoTaskToDownloader()

    def _handleCancelTask(self, task):
        try:
            self.todoQueue.remove(task.uidOfTaskToCancel)
        except ValueError:
            print("Task %i not in todo list" % task.uidOfTaskToCancel)
    
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
        self.uploader.join(1.5)

    def _setBusy(self):
        self.idle.clear()
    
    def _setIdleIfNothingOngoingOrTodo(self):
        if self.commandQueue.empty() and \
                len(self.todoQueue) == 0 and \
                self.submitQueue.unfinished_tasks == 0 and \
                self.uploader.isIdling():
            self.idle.set()        
    
    def run(self):
        while self.running:
            task = self.commandQueue.get() # blocks until work to do
            self._setBusy()
            
            if type(task) == UploadTask:
                self._handleUploadTask(task)
            elif type(task) == CancelUploadTask:
                self._handleCancelTask(task)
            elif type(task) == UploadCompletedTask:
                self._handleUploadCompletedTask(task)
            elif type(task) == tasks.TerminateTask:
                self._handleTerminateTask(task)

            self._setIdleIfNothingOngoingOrTodo()
            self.commandQueue.task_done()
                        
UPLOADER = UploadManager()

def upload(localPath, remoteParentId, remoteName, key=None, cb=None):
    return UPLOADER.submitTask(UploadTask.Create(localPath, remoteParentId, remoteName, key, cb))

def cancel(uid, cb=None):
    UPLOADER.submitTask(CancelUploadTask.Create(uid, cb))

def wait():
    UPLOADER.waitUntilTasksDone()

def terminate():
    UPLOADER.submitTask(tasks.TerminateTask())
    UPLOADER.waitUntilTerminated()
    
    
