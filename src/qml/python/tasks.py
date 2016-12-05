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

class ListTask(Task):
    
    def __init__(self, cb=None, *args):
        super().__init__(cb)
