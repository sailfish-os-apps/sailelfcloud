'''
Created on Aug 22, 2016

@author: teemu
'''

import uidGenerator

class Task(object):
    
    def __init__(self, cb=None):
        self.__uid = uidGenerator.getUid()
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
        

class DownloadTask(XferTask):

    @classmethod
    def Create(cls, localPath, remoteParentId, remoteName, key=None, cb=None):
        return cls(cb, localPath, remoteParentId, remoteName, key)
    
    def __init__(self, cb, remoteName, remoteParentId, localPath, key):
        self.remoteName = remoteName
        self.remoteParentId = remoteParentId
        self.localPath = localPath
        self.key = key

class DownloadCompletedTask(DownloadTask):
    
    @classmethod
    def Create(cls, task):
        return cls(task.cbObj, task.localPath, task.remoteParentId, task.remoteName, task.key)

 
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

class CancelDownloadTask(CancelTask):

    @classmethod
    def Create(cls, uidToCancel, cb):
        return cls(uidToCancel, cb)
    
    def __init__(self, uidToCancel, cb):
        super().__init__(uidToCancel, cb)

