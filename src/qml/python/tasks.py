'''
Created on Aug 22, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import uidgenerator

class Task(object):
    
    def __init__(self, startCb=None, completedCb=None, failedCb=None):
        self.__uid = uidgenerator.getUid()
        self.__startCb = startCb
        self.__completedCb = completedCb
        self.__failedCb = failedCb

    @property
    def uid(self):
        return self.__uid

    @property
    def startCb(self):
        return self.__startCb

    @property
    def completedCb(self):
        return self.__completedCb

    @property
    def failedCb(self):
        return self.__failedCb
    
    def __eq__(self, other):
        if isinstance(other, int):
            return other == self.__uid
        else:
            return self.__dict__ == other.__dict__
    

class TerminateTask(Task):
    
    def __init__(self, cb=None, *args):
        super().__init__(completedCb=cb)    

class XferTask(Task):
    
    def __init__(self, startCb, completedCb, failedCb, *args):
        super().__init__(startCb, completedCb, failedCb)
        self.__running = True
        
    @property
    def running(self):
        return self.__running
    
    @running.setter
    def running(self, r):
        self.__running = r 
        
 
class WaitCompletionTask(Task):

    def __init__(self):
        self.uid = None     
    
class CancelTask(XferTask):

    def __init__(self, uidToCancel, cb):
        super().__init__(startCb=None, completedCb=cb, failedCb=None)
        self.__uidOfTaskToCancel = uidToCancel
        
    @property
    def uidOfTaskToCancel(self):
        return self.__uidOfTaskToCancel 

class PauseTask(XferTask):

    def __init__(self, uidToPause, cb):
        super().__init__(startCb=None, completedCb=cb, failedCb=None)
        self.__uidOfTaskToPause = uidToPause
        
    @property
    def uidOfTaskToPause(self):
        return self.__uidOfTaskToPause 

class ResumeTask(XferTask):

    def __init__(self, uidToResume, cb):
        super().__init__(startCb=None, completedCb=cb, failedCb=None)
        self.__uidOfTaskToResume = uidToResume
        
    @property
    def uidOfTaskToResume(self):
        return self.__uidOfTaskToResume 

class ListTask(Task):
    
    def __init__(self, cb=None, *args):
        super().__init__(completedCb=cb)
