'''
Created on Aug 22, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import uidgenerator

class Task(object):
    
    def __init__(self, cb=None):
        self.__uid = uidgenerator.getUid()
        self.__cb = cb

    @property
    def uid(self):
        return self.__uid

    @property
    def cb(self):
        return self.__cb
    
    def __eq__(self, other):
        if isinstance(other, int):
            return other == self.__uid
        else:
            return self.__dict__ == other.__dict__
    

class TerminateTask(Task):
    
    def __init__(self, cb=None, *args):
        super().__init__(cb)    

class XferTask(Task):
    
    def __init__(self, cb, *args):
        super().__init__(cb)
        self.__running = True
        
    @property
    def running(self):
        return self.__running
    
    @running.setter
    def running(self, r):
        self.__running = r 
        
 
class WaitCompletionTask(object):

    def __init__(self):
        self.uid = None     
    
class CancelTask(XferTask):

    def __init__(self, uidToCancel, cb):
        super().__init__(cb)
        self.__uidOfTaskToCancel = uidToCancel
        
    @property
    def uidOfTaskToCancel(self):
        return self.__uidOfTaskToCancel 

class PauseTask(XferTask):

    def __init__(self, uidToPause, cb):
        super().__init__(cb)
        self.__uidOfTaskToPause = uidToPause
        
    @property
    def uidOfTaskToPause(self):
        return self.__uidOfTaskToPause 

class ResumeTask(XferTask):

    def __init__(self, uidToResume, cb):
        super().__init__(cb)
        self.__uidOfTaskToResume = uidToResume
        
    @property
    def uidOfTaskToResume(self):
        return self.__uidOfTaskToResume 

class ListTask(Task):
    
    def __init__(self, cb=None, *args):
        super().__init__(cb)
