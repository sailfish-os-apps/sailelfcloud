'''
Created on Sep 15, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import threading
import traceback
import elfcloudclient
import queue
from collections import deque
import tasks
import logger

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
        self.size = 0
        
    def __str__(self):
        return "DownloadTask: %i, %s, %s, %s, %i, %s" % (self.uid, self.localPath,
                                                         self.remoteParentId, self.remoteName,
                                                         self.size, self.key)
        
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

class PauseDownloadTask(tasks.PauseTask):

    @classmethod
    def Create(cls, uidToPause, cb):
        return cls(uidToPause, cb)
    
    def __init__(self, uidToPause, cb):
        super().__init__(uidToPause, cb)
        
    def __str__(self):
        return "PauseDownloadTask: %i" % (self.uidOfTaskToPause)

class ResumeDownloadTask(tasks.ResumeTask):

    @classmethod
    def Create(cls, uidToResume, cb):
        return cls(uidToResume, cb)
    
    def __init__(self, uidToResume, cb):
        super().__init__(uidToResume, cb)
        
    def __str__(self):
        return "ResumeDownloadTask: %i" % (self.uidToResume)

class ListDownloadTask(tasks.ListTask):

    @classmethod
    def Create(cls, cb):
        return cls(cb)
    
    def __init__(self, cb):
        super().__init__(cb)
        
    def __str__(self):
        return "ListTask"

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
    
    @staticmethod
    def _getRemoteSize(remoteParentId, remoteName):
        return elfcloudclient.getDataItemInfo(remoteParentId, remoteName)['size']

    @staticmethod
    def __cancelCb(task, *args):
        return not task.running

    def _handleDownloadTask(self, task):
        try:
            task.size = self._getRemoteSize(task.remoteParentId, task.remoteName)
            elfcloudclient.download(task.remoteParentId, task.remoteName, task.localPath, None, task.chunkCb,
                                    lambda *args : self.__cancelCb(task, *args))
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
        self.pausedList = list()
        self.currentDownloaderTask = None
        self.downloader = Downloader(self.submitQueue, self.commandQueue)
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
            self.currentDownloaderTask = self.todoQueue.popleft()
            self.submitQueue.put(self.currentDownloaderTask)

    def _handleDownloadTask(self, task):
        self.todoQueue.append(task)
        self._submitTodoTaskToDownloader()

    def _callCb(self, task):
        if callable(task.cb):
            task.cb() if not task.exception else task.cb(task.exception)

    def _handleDownloadCompletedTask(self, task):
        self._callCb(task)
        self.currentDownloaderTask = None
        self._submitTodoTaskToDownloader()

    def _handleCancelTask(self, task):
        if self.currentDownloaderTask and self.currentDownloaderTask.uid == task.uidOfTaskToCancel:
            self.currentDownloaderTask.running = False
        else:        
            try:
                self.todoQueue.remove(task.uidOfTaskToCancel)
            except ValueError:
                logger.error("Task %i not in todo list" % task.uidOfTaskToCancel)

    def _handlePauseTask(self, task):
        if self.currentDownloaderTask and self.currentDownloaderTask.uid == task.uidOfTaskToPause:
            self.currentDownloaderTask.running = False
            self.pausedList.append(self.currentDownloaderTask)            
        else:        
            try:
                l = list(self.todoQueue)
                self.pausedList.append(l[l.index(task.uidOfTaskToPause)])
                self.todoQueue.remove(task.uidOfTaskToPause)
            except ValueError:
                logger.error("Task %i not in todo list" % task.uidOfTaskToPause)

    def _handleResumeTask(self, task):
        try:
            self.todoQueue.append(self.pausedList[self.pausedList.index(task.uidOfTaskToResume)])
            self.pausedList.remove(task.uidOfTaskToResume)
        except ValueError:
            logger.error("Task %i not in paused list" % task.uidOfTaskToResume)
    
    def _submitTerminateTaskToDownloader(self):
        try:
            self.submitQueue.put(tasks.TerminateTask(), timeout=1)
        except queue.Full:
            logger.error("takes too long to terminate downloader")
            return
        
        self.submitQueue.join()
    
    def _handleTerminateTask(self, task):
        self.running = False
        self._submitTerminateTaskToDownloader()
        self.downloader.join(1.5)

    def _handleListDownloadTask(self, task):
        downloads = []

        if self.currentDownloaderTask:
            downloads.append({"uid":self.currentDownloaderTask.uid,
                              "remoteName":self.currentDownloaderTask.remoteName,
                              "parentId":self.currentDownloaderTask.remoteParentId,
                              "size":self.currentDownloaderTask.size,
                              "state":"ongoing"})

        for t in self.todoQueue:
            downloads.append({"uid":t.uid,
                              "remoteName":t.remoteName,
                              "parentId":t.remoteParentId,
                              "size":t.size,
                              "state":"todo"})

        for t in self.pausedList:
            downloads.append({"uid":t.uid,
                              "remoteName":t.remoteName,
                              "parentId":t.remoteParentId,
                              "size":t.size,
                              "state":"paused"})

        if task.cb: task.cb(downloads)

    def _setBusy(self):
        self.idle.clear()
    
    def _setIdleIfNothingOngoingOrTodo(self):
        if self.commandQueue.empty() and \
                len(self.todoQueue) == 0 and \
                self.submitQueue.unfinished_tasks == 0 and \
                self.downloader.isIdling():
            self.idle.set()        
    
    def run(self):
        try:
            while self.running:
                task = self.commandQueue.get() # blocks until work to do
                self._setBusy()
                
                if type(task) == DownloadTask:
                    self._handleDownloadTask(task)
                elif type(task) == CancelDownloadTask:
                    self._handleCancelTask(task)
                elif type(task) == PauseDownloadTask:
                    self._handlePauseTask(task)
                elif type(task) == ResumeDownloadTask:
                    self._handleResumeTask(task)
                elif type(task) == DownloadCompletedTask:
                    self._handleDownloadCompletedTask(task)
                elif type(task) == tasks.TerminateTask:
                    self._handleTerminateTask(task)
                elif type(task) == ListDownloadTask:
                    self._handleListDownloadTask(task)
    
                self._setIdleIfNothingOngoingOrTodo()
                self.commandQueue.task_done()
        except:
            logger.error("Downloader had unhandled exception: %s" % traceback.format_exc())
                        
DOWNLOADER = DownloadManager()

def download(localPath, remoteParentId, remoteName, key=None, cb=None, chunkCb=None):
    return DOWNLOADER.submitTask(DownloadTask.Create(localPath, remoteParentId, remoteName, key, cb, chunkCb))

def cancel(uid, cb=None):
    DOWNLOADER.submitTask(CancelDownloadTask.Create(uid, cb))

def pause(uid, cb=None):
    DOWNLOADER.submitTask(PauseDownloadTask.Create(uid, cb))

def resume(uid, cb=None):
    DOWNLOADER.submitTask(ResumeDownloadTask.Create(uid, cb))

def listAll(cb):
    DOWNLOADER.submitTask(ListDownloadTask.Create(cb))

def wait():
    """Returns when all running tasks are compeleted."""
    DOWNLOADER.waitUntilTasksDone()

def terminate():
    DOWNLOADER.submitTask(tasks.TerminateTask())
    DOWNLOADER.waitUntilTerminated()
    
    
