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
    def Create(cls, localPath, remoteParentId, remoteName, key=None, startCb=None, completedCb=None, chunkCb=None, failedCb=None):
        return cls(startCb, completedCb, localPath, remoteParentId, remoteName, key, chunkCb, failedCb)
    
    def __init__(self, startCb, completedCb, localPath, remoteParentId, remoteName, key, chunkCb, failedCb):
        super().__init__(startCb, completedCb, failedCb)
        self.localPath = localPath
        self.remoteParentId = remoteParentId
        self.remoteName = remoteName
        self.key = key
        self.chunkCb = chunkCb
        self.size = 0
        self.running = True
        
    def __str__(self):
        return "DownloadTask: %i, %s, %s, %s, %i, %s, %s" % (self.uid, self.localPath,
                                                         self.remoteParentId, self.remoteName,
                                                         self.size, self.key, self.running)
        
class DownloadCompletedTask(tasks.Task):
    
    @classmethod
    def Create(cls, task):
        o = cls()
        o.task = task
        return o

    def __str__(self):
        return "DownloadCompletedTask" + str(self.task)

class DownloadFailedTask(tasks.Task):
    
    @classmethod
    def Create(cls, task, exception=None):
        o = cls()
        o.task = task
        o.__exc = exception
        return o

    @property
    def exception(self):
        return self.__exc
    
    def __str__(self):
        return "DownloadFailedTask [exception: %s]: " % (str(self.exception)) + str(self.task)

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

    def _submitDownloadTaskDone(self, task):
        self.responseQueue.put(DownloadCompletedTask.Create(task))

    def _submitDownloadTaskFailed(self, task, exception=None):
        self.responseQueue.put(DownloadFailedTask.Create(task, exception))
    
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
            self._submitDownloadTaskFailed(task, e)

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
            if callable(self.currentDownloaderTask.startCb): self.currentDownloaderTask.startCb()
            self.submitQueue.put(self.currentDownloaderTask)

    def _handleDownloadTask(self, task):
        self.todoQueue.append(task)
        self._submitTodoTaskToDownloader()


    def _handleDownloadCompletedTask(self, task):
        if task.task.running and callable(task.task.completedCb):
            task.task.completedCb() 
        
        self.currentDownloaderTask = None
        self._submitTodoTaskToDownloader()

    def _pauseTask(self, uid):
        if self.currentDownloaderTask and self.currentDownloaderTask.uid == uid:
            self.currentDownloaderTask.running = False
            self.pausedList.append(self.currentDownloaderTask)
            self.currentDownloaderTask = None
        elif self.todoQueue.count(uid):        
            self._moveTaskOfUid(uid, self.todoQueue, self.pausedList)
        else:
            logger.error("Task %i not current nor in todo list" % uid)

    def _handleDownloadFailedTask(self, task):
        if task.task.running and callable(task.task.failedCb):
            task.task.failedCb(task.exception)
        
        self._pauseTask(task.task.uid)

    def _handleCancelTask(self, task):
        logger.debug("Cancelling task %i" % task.uidOfTaskToCancel)
        if self.currentDownloaderTask and self.currentDownloaderTask.uid == task.uidOfTaskToCancel:
            self.currentDownloaderTask.running = False
        elif self.todoQueue.count(task.uidOfTaskToCancel):
            self.todoQueue.remove(task.uidOfTaskToCancel)
        elif self.pausedList.count(task.uidOfTaskToCancel):
            self.pausedList.remove(task.uidOfTaskToCancel)
        else:
            logger.error("Task %i not current nor in todo list or paused list" % task.uidOfTaskToCancel)

    @staticmethod
    def _removeTaskOfUid(uid, from_):
        l = list(from_)
        t = l[l.index(uid)]
        from_.remove(t)
        return t

    @staticmethod
    def _moveTaskOfUid(uid, from_, to):
        to.append(DownloadManager._removeTaskOfUid(uid, from_))

    def _handlePauseTask(self, task):
        logger.debug("Pausing task %i" % task.uidOfTaskToPause)
        self._pauseTask(task.uidOfTaskToPause)

    def _handleResumeTask(self, task):
        logger.debug("Resuming task %i" % task.uidOfTaskToResume)
        if self.pausedList.count(task.uidOfTaskToResume):
            taskToResume = self._removeTaskOfUid(task.uidOfTaskToResume, self.pausedList)
            taskToResume.running = True
            self._handleDownloadTask(taskToResume)
        else:
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

    @staticmethod
    def _createTaskInfoDict(task, state):
        return {"uid":task.uid,
                "remoteName":task.remoteName,
                "parentId":task.remoteParentId,
                "size":task.size,
                "state":state}

    def _handleListDownloadTask(self, task):
        downloads = []

        if self.currentDownloaderTask and self.currentDownloaderTask.running:
            downloads.append(self._createTaskInfoDict(self.currentDownloaderTask, "ongoing"))
        
        for t in self.todoQueue:
            downloads.append(self._createTaskInfoDict(t, "todo"))

        for t in self.pausedList:
            downloads.append(self._createTaskInfoDict(t, "paused"))

        if callable(task.completedCb): task.completedCb(downloads)

    def _setBusy(self):
        self.idle.clear()
    
    def _setIdleIfNothingOngoingOrTodo(self):
        if self.commandQueue.empty() and \
                len(self.todoQueue) == 0 and \
                self.submitQueue.unfinished_tasks == 0 and \
                self.downloader.isIdling():
            self.idle.set()        
    
    def run(self):
        while self.running:
            try:
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
                elif type(task) == DownloadFailedTask:
                    self._handleDownloadFailedTask(task)
                elif type(task) == tasks.TerminateTask:
                    self._handleTerminateTask(task)
                elif type(task) == ListDownloadTask:
                    self._handleListDownloadTask(task)
    
                self._setIdleIfNothingOngoingOrTodo()
                self.commandQueue.task_done()
            except:
                logger.error("DownloaderManager had unhandled exception: %s" % traceback.format_exc())
                        
DOWNLOADER = DownloadManager()

def download(localPath, remoteParentId, remoteName, key=None, startCb=None, completedCb=None, chunkCb=None, failedCb=None):
    return DOWNLOADER.submitTask(DownloadTask.Create(localPath, remoteParentId, remoteName, key,
                                                     startCb, completedCb, chunkCb, failedCb))

def cancel(uid, cb=None):
    DOWNLOADER.submitTask(CancelDownloadTask.Create(uid, cb))

def pause(uid, cb=None):
    DOWNLOADER.submitTask(PauseDownloadTask.Create(uid, cb))

def resume(uid, cb=None):
    DOWNLOADER.submitTask(ResumeDownloadTask.Create(uid, cb))

def listAll(cb):
    DOWNLOADER.submitTask(ListDownloadTask.Create(cb))

def wait():
    """Returns when all running tasks are compeleted (paused tasks are ignored)."""
    DOWNLOADER.waitUntilTasksDone()

def terminate():
    DOWNLOADER.submitTask(tasks.TerminateTask())
    DOWNLOADER.waitUntilTerminated()
    
    
