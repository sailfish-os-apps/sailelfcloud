'''
Created on Jul 19, 2016

@author: teemu
'''

import elfCloudAdapter
import threading
import queue
from collections import deque
import tasks



# class XferQueue(object):
#     
#     def __init__(self):
#         self.queue = queue.Queue()
#         
#     def push(self, task):
#         self.queue.put(task)
# 
#     def pop(self):
#         task = self.queue.get()
#         return task
#     
#     def completed(self):
#         self.queue.task_done()        
#     
#     def prune(self):
#         tasks = {}
#         task = self.queue.get_nowait()
#         
#         while task:
#             tasks[task.uid] = task
#             self.queue.task_done()
#             try:
#                 task = self.queue.get_nowait()
#             except queue.Empty:
#                 task = None
#             
#         return tasks
#     
#     def removeSpecific(self, uid):
#         tasks = self.prune()
#         tasks.pop(uid, None)
#         
#         for task in tasks.values():
#             self.push(task)
#     
#     def waitUntilEmpty(self):
#         self.queue.join()




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
    
    def waitUntilTerminated(self):
        pass
    
    def submitTask(self, task):
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
            
            if isinstance(task, tasks.DownloadTask):
                self._handleDownloadTask(task)
            elif isinstance(task, tasks.CancelTask):
                self._handleCancelTask(task)
            elif isinstance(task, tasks.DownloadCompletedTask):
                self._handleDownloadCompletedTask(task)
            
            self.tasks.task_done()


