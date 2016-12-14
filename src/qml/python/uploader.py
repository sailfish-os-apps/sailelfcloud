'''
Created on Sep 15, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import os
import threading
import elfcloudclient
import queue
from collections import deque
import tasks

class UploadTask(tasks.XferTask):
    
    @classmethod
    def Create(cls, localPath, remoteParentId, remoteName, key=None, startCb=None, completedCb=None, chunkCb=None):
        return cls(startCb, completedCb, localPath, remoteParentId, remoteName, key, chunkCb)
    
    def __init__(self, startCb, completedCb, localPath, remoteParentId, remoteName, key, chunkCb):
        super().__init__(startCb, completedCb)
        self.localPath = localPath
        self.remoteParentId = remoteParentId
        self.remoteName = remoteName
        self.key = key
        self.chunkCb = chunkCb
        
    def __str__(self):
        return "UploadTask: %i, %s, %s, %s, %s" % (self.uid, self.localPath, self.remoteParentId, self.remoteName, self.key)
        
class UploadCompletedTask(UploadTask):
    
    @classmethod
    def Create(cls, task, exception=None):
        o = cls(task.startCb, task.completedCb, task.localPath, task.remoteParentId, task.remoteName, task.key, task.chunkCb)
        o.__exc = exception
        return o

    @property
    def exception(self):
        return self.__exc

    def __str__(self):
        return "UploadCompletedTask: %i %s" % (self.uid, str(self.exc) if self.exc else "")

class CancelUploadTask(tasks.CancelTask):

    @classmethod
    def Create(cls, uidToCancel, cb):
        return cls(uidToCancel, cb)
    
    def __init__(self, uidToCancel, cb):
        super().__init__(uidToCancel, cb)
        
    def __str__(self):
        return "CancelTask: %i" % (self.uidOfTaskToCancel)

class ListUploadTask(tasks.ListTask):

    @classmethod
    def Create(cls, cb):
        return cls(cb)
    
    def __init__(self, cb):
        super().__init__(cb)
        
    def __str__(self):
        return "ListTask"

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

    def _submitUploadTaskDone(self, task, exception=None):
        self.responseQueue.put(UploadCompletedTask.Create(task, exception))

    def _handleUploadTask(self, task):
        try:
            elfcloudclient.upload(task.remoteParentId, task.remoteName, task.localPath, task.chunkCb)
            self._submitUploadTaskDone(task)
        except elfcloudclient.ClientException as e:
            self._submitUploadTaskDone(task, e)

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
        self.currentUploaderTask = None        
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
   
    def _submitTodoTaskToUploader(self):
        if len(self.todoQueue) and self.submitQueue.unfinished_tasks == 0:
            self.currentUploaderTask = self.todoQueue.popleft()
            self.submitQueue.put(self.currentUploaderTask)

    def _handleUploadTask(self, task):
        self.todoQueue.append(task)
        self._submitTodoTaskToUploader()

    def _handleUploadCompletedTask(self, task):
        if callable(task.completedCb): task.completedCb() if not task.exception else task.completedCb(task.exception)
        self.currentUploaderTask = None
        self._submitTodoTaskToUploader()

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
        
    def _handleListUploadTask(self, task):
        uploads = []

        if self.currentUploaderTask:
            uploads.append({"uid":self.currentUploaderTask.uid,
                            "remoteName":self.currentUploaderTask.remoteName,
                            "parentId":self.currentUploaderTask.remoteParentId,
                            "size":os.path.getsize(self.currentUploaderTask.localPath),
                            "state":"ongoing"})

        for t in self.todoQueue:
            uploads.append({"uid":t.uid,
                            "remoteName":t.remoteName,
                            "parentId":t.remoteParentId,
                            "size":os.path.getsize(t.localPath),
                            "state":"todo"})
            
        if task.completedCb: task.completedCb(uploads)

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
            elif type(task) == ListUploadTask:
                self._handleListUploadTask(task)

            self._setIdleIfNothingOngoingOrTodo()
            self.commandQueue.task_done()
                        
UPLOADER = UploadManager()

def upload(localPath, remoteParentId, remoteName, key=None, startCb=None, completedCb=None, chunkCb=None):
    return UPLOADER.submitTask(UploadTask.Create(localPath, remoteParentId, remoteName, key, startCb, completedCb, chunkCb))

def cancel(uid, cb=None):
    UPLOADER.submitTask(CancelUploadTask.Create(uid, cb))

def listAll(cb):
    UPLOADER.submitTask(ListUploadTask.Create(cb))

def wait():
    """Returns when all running tasks are compeleted."""
    UPLOADER.waitUntilTasksDone()

def terminate():
    UPLOADER.submitTask(tasks.TerminateTask())
    UPLOADER.waitUntilTerminated()
    
    
