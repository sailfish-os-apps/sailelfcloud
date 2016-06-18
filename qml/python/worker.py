'''
Created on Jun 12, 2016

@author: teemu
'''

import threading
import queue

class WorkerThread(threading.Thread):

    def __init__(self, tasks):
        super(WorkerThread, self).__init__(daemon=True)
        self.tasks = tasks
        self.start()

    def run(self):
        while True:
            func, args, kargs = self.tasks.get() # blocks until work to do

            try:
                func(*args, **kargs)
            except Exception as e:
                print(e)
            finally:
                self.tasks.task_done()
 
class ThreadPool:
        
    def __init__(self, workerCount):
        self.tasks = queue.Queue(workerCount)
        for _ in range(workerCount): WorkerThread(self.tasks)

    def executeTask(self, func, *args, **kargs):
        self.tasks.put((func, args, kargs))
        return True

    def waitTasksCompletion(self):
        self.tasks.join()

class WorkData():
    
    def __init__(self):
        self._event = threading.Event()
        self._data = None        
    
    def setData(self, data):
        self._data = data
        self._event.set()
        
    def getData(self):
        self._event.clear()
        return self._data
    
    def waitForData(self):
        self._event.wait()
        return self.getData()

MAX_WORKERS = 5
threadPool = ThreadPool(MAX_WORKERS)

from functools import wraps

def run_async(func):
    @wraps(func)
    def async_func(*args, **kwargs):
        return threadPool.executeTask(func, *args, **kwargs)

    return async_func

