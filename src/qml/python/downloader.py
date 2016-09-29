'''
Created on Sep 15, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import threading
import elfcloudclient
import queue
from collections import deque
import tasks

class DownloadTask(tasks.XferTask):
    
    @classmethod
    def Create(cls, localPath, remoteParentId, remoteName, key=None, cb=None, chunkCb=None):
        return cls(cb, localPath, remoteParentId, remoteName, key, chunkCb)
    
    def __init__(self, cb, localPath, remoteParentId, remoteName, key, chunkCb):
        super().__init__(cb)
        self.localPath = localPath
        self.remoteParentId = remoteParentId
        self.remoteName = remoteName
        self.key = key
        self.chunkCb = chunkCb
        
    def __str__(self):
        return "DownloadTask: %i, %s, %s, %s, %s" % (self.uid, self.localPath, self.remoteParentId, self.remoteName, self.key)
        
class DownloadCompletedTask(DownloadTask):
    
    @classmethod
    def Create(cls, task, exception=None):
        o = cls(task.cb, task.localPath, task.remoteParentId, task.remoteName, task.key, task.chunkCb)
        o.__exc = exception
        return o

    @property
    def exception(self):
        return self.__exc

    def __str__(self):
        return "DownloadCompletedTask: %i %s" % (self.uid, str(self.exc) if self.exc else "")

class CancelDownloadTask(tasks.CancelTask):

    @classmethod
    def Create(cls, uidToCancel, cb):
        return cls(uidToCancel, cb)
    
    def __init__(self, uidToCancel, cb):
        super().__init__(uidToCancel, cb)
        
    def __str__(self):
        return "CancelDownloadTask: %i" % (self.uidOfTaskToCancel)

class Downloader(threading.Thread):
    
    def __init__(self, commandQueue, responseQueue):
        super(Downloader, self).__init__(daemon=True)
        self.commandQueue = commandQueue
        self.responseQueue = responseQueue
        self.idle = threading.Event()
        self.running = True
        self.idle.set()
        self.start()

    def isIdling(self):
        return self.idle.isSet()

    def _submitDownloadTaskDone(self, task, exception=None):
        self.responseQueue.put(DownloadCompletedTask.Create(task, exception))

    def _handleDownloadTask(self, task):
        try:
            elfcloudclient.download(task.remoteParentId, task.remoteName, task.localPath, None, task.chunkCb)
            self._submitDownloadTaskDone(task)
        except elfcloudclient.ClientException as e:
            self._submitDownloadTaskDone(task, e)

    def _setBusy(self):
        self.idle.clear()

    def _setIdle(self):
        self.idle.set()

    def run(self):
        while self.running:
            task = self.commandQueue.get()
            self._setBusy()
            
            if type(task) == DownloadTask:
                self._handleDownloadTask(task)
            elif type(task) == tasks.TerminateTask:
                self.running = False
             
            self._setIdle()
            self.commandQueue.task_done()


class DownloadManager(threading.Thread):
    
    def __init__(self):
        super(DownloadManager, self).__init__(daemon=True)
        self.running = True
        self.idle = threading.Event()
        self.commandQueue = queue.Queue()
        self.submitQueue = queue.Queue(1)
        self.todoQueue = deque()
        self.uploader = Downloader(self.submitQueue, self.commandQueue)
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

    def _handleDownloadTask(self, task):
        self.todoQueue.append(task)
        self._submitTodoTaskToDownloader()

    def _callCb(self, task):
        if callable(task.cb):
            task.cb() if not task.exception else task.cb(task.exception)

    def _handleDownloadCompletedTask(self, task):
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
            
            if type(task) == DownloadTask:
                self._handleDownloadTask(task)
            elif type(task) == CancelDownloadTask:
                self._handleCancelTask(task)
            elif type(task) == DownloadCompletedTask:
                self._handleDownloadCompletedTask(task)
            elif type(task) == tasks.TerminateTask:
                self._handleTerminateTask(task)

            self._setIdleIfNothingOngoingOrTodo()
            self.commandQueue.task_done()
                        
DOWNLOADER = DownloadManager()

def download(localPath, remoteParentId, remoteName, key=None, cb=None, chunkCb=None):
    return DOWNLOADER.submitTask(DownloadTask.Create(localPath, remoteParentId, remoteName, key, cb, chunkCb))

def cancel(uid, cb=None):
    DOWNLOADER.submitTask(CancelDownloadTask.Create(uid, cb))

def wait():
    """Returns when all running tasks are compeleted."""
    DOWNLOADER.waitUntilTasksDone()

def terminate():
    DOWNLOADER.submitTask(tasks.TerminateTask())
    DOWNLOADER.waitUntilTerminated()
    
    
