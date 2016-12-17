'''
Created on Sep 15, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import os
import logger
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
        self.size = os.path.getsize(self.localPath)
        self.uploadedSize = 0
        
    def __str__(self):
        return "UploadTask: %i, %s, %s, %s, %i, %i, %s" % (self.uid, self.localPath, self.remoteParentId, 
                                                       self.remoteName, self.size, self.uploadedSize, self.key)
        
class UploadCompletedTask(UploadTask):
    
    @classmethod
    def Create(cls, task, running, exception=None):
        o = cls(task.startCb, task.completedCb, task.localPath, task.remoteParentId, task.remoteName, task.key, task.chunkCb)
        o.running = running
        o.__exc = exception
        return o

    @property
    def exception(self):
        return self.__exc

    def __str__(self):
        return "UploadCompletedTask: %i %s %s" % (self.uid, self.running, str(self.exc) if self.exc else "")

class CancelUploadTask(tasks.CancelTask):

    @classmethod
    def Create(cls, uidToCancel, cb):
        return cls(uidToCancel, cb)
    
    def __init__(self, uidToCancel, cb):
        super().__init__(uidToCancel, cb)
        
    def __str__(self):
        return "CancelTask: %i" % (self.uidOfTaskToCancel)

class PauseUploadTask(tasks.PauseTask):

    @classmethod
    def Create(cls, uidToPause, cb):
        return cls(uidToPause, cb)
    
    def __init__(self, uidToPause, cb):
        super().__init__(uidToPause, cb)
        
    def __str__(self):
        return "PauseUploadTask: %i" % (self.uidOfTaskToPause)

class ResumeUploadTask(tasks.ResumeTask):

    @classmethod
    def Create(cls, uidToResume, cb):
        return cls(uidToResume, cb)
    
    def __init__(self, uidToResume, cb):
        super().__init__(uidToResume, cb)
        
    def __str__(self):
        return "ResumeUploadTask: %i" % (self.uidToResume)

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

    @staticmethod
    def __cancelCb(task, *args):
        return not task.running

    def _handleUploadTask(self, task):
        try:
            elfcloudclient.upload(task.remoteParentId, task.remoteName, task.localPath, task.chunkCb,
                                  lambda *args : self.__cancelCb(task, *args))
            self._submitUploadTaskDone(task)
        except elfcloudclient.ClientException as e:
            logger.error("Upload exception: %s" % str(e))
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
        self.pausedList = list()
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
            if callable(self.currentUploaderTask.startCb): self.currentUploaderTask.startCb()
            self.submitQueue.put(self.currentUploaderTask)

    def _handleUploadTask(self, task):
        self.todoQueue.append(task)
        self._submitTodoTaskToUploader()

    def _handleUploadCompletedTask(self, task):
        if task.running:
            if callable(task.completedCb): task.completedCb() if not task.exception else task.completedCb(task.exception)

        self.currentUploaderTask = None
        self._submitTodoTaskToUploader()

    def _handleCancelTask(self, task):
        if self.currentUploaderTask and self.currentUploaderTask.uid == task.uidOfTaskToCancel:
            self.currentUploaderTask.running = False
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
        to.append(UploadManager._removeTaskOfUid(uid, from_))
    
    def _handlePauseTask(self, task):
        logger.debug("Pausing task %i" % task.uidOfTaskToPause)
        if self.currentUploaderTask and self.currentUploaderTask.uid == task.uidOfTaskToPause:
            self.currentUploaderTask.running = False
            self.pausedList.append(self.currentUploaderTask)            
        elif self.todoQueue.count(task.uidOfTaskToPause):        
            self._moveTaskOfUid(task.uidOfTaskToPause, self.todoQueue, self.pausedList)
        else:
            logger.error("Task %i not current nor in todo list" % task.uidOfTaskToPause)

    def _handleResumeTask(self, task):
        logger.debug("Resuming task %i" % task.uidOfTaskToResume)
        if self.pausedList.count(task.uidOfTaskToResume):
            taskToResume = self._removeTaskOfUid(task.uidOfTaskToResume, self.pausedList)
            taskToResume.running = True
            self._handleUploadTask(taskToResume)
        else:
            logger.error("Task %i not in paused list" % task.uidOfTaskToResume)    
    
    def _submitTerminateTaskToUploader(self):
        try:
            self.submitQueue.put(tasks.TerminateTask(), timeout=1)
        except queue.Full:
            logger.error("takes too long to terminate uploader")
            return
        
        self.submitQueue.join()
    
    def _handleTerminateTask(self, task):
        self.running = False
        self._submitTerminateTaskToUploader()
        self.uploader.join(1.5)

    @staticmethod
    def _createTaskInfoDict(task, state):
        return {"uid":task.uid,
                "remoteName":task.remoteName,
                "parentId":task.remoteParentId,
                "size":task.size,
                "state":state}

    def _handleListUploadTask(self, task):
        uploads = []

        if self.currentUploaderTask:
            uploads.append(self._createTaskInfoDict(self.currentUploaderTask, "ongoing"))

        for t in self.todoQueue:
            uploads.append(self._createTaskInfoDict(t, "todo"))
            
        for t in self.pausedList:
            uploads.append(self._createTaskInfoDict(t, "paused"))
            
        if callable(task.completedCb): task.completedCb(uploads)

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
            elif type(task) == PauseUploadTask:
                self._handlePauseTask(task)
            elif type(task) == ResumeUploadTask:
                self._handleResumeTask(task)
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

def pause(uid, cb=None):
    UPLOADER.submitTask(PauseUploadTask.Create(uid, cb))

def resume(uid, cb=None):
    UPLOADER.submitTask(ResumeUploadTask.Create(uid, cb))

def listAll(cb):
    UPLOADER.submitTask(ListUploadTask.Create(cb))

def wait():
    """Returns when all running tasks are compeleted (paused tasks are ignored)."""
    UPLOADER.waitUntilTasksDone()

def terminate():
    UPLOADER.submitTask(tasks.TerminateTask())
    UPLOADER.waitUntilTerminated()
    
    
