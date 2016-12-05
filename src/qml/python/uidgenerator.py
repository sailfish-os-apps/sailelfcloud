'''
Created on Sep 15, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import threading

def atomic(func):
    from functools import wraps
    @wraps(func)
    def _atomically(self, *args, **kwargs):
        with self.lock:
            return func(self, *args, **kwargs)
    return _atomically

class UidGenerator(object):

    def __init__(self, value=0):
        self.lock = threading.Lock()
        self.value = value

    @atomic
    def get(self):
        self.value += 1
        return self.value
    
    @atomic
    def peek(self):
        return self.value

UID_GENERATOR = UidGenerator()

def getUid():
    return UID_GENERATOR.get()

def peekUid():
    return UID_GENERATOR.peek()
