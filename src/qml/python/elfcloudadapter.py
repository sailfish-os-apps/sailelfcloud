'''
Created on Sep 18, 2016

This module provides asynchronous interface of various elfCLOUD operations
for applications in QML.

Interface is purposely chosen to be asynchronous in order to help QML code
to handle calls from UI thread context. Responses to calls are passed to
QML via signals using pyOtherside. Caller can provide context for the signal
via `cbObj` arguments of various functions. Typically the `callback object`
is QtObject which has user-specified callback for completion and failure cases.

This allows using of callback instead of signals in QML side and callback can
be cleared if the owner of the `callback object` goes out of scope.  

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import elfcloudclient
import exceptionhandler
import worker
import logger

try:
    import pyotherside
except ImportError:
    import sys
    # Allow testing Python backend alone.
    print("PyOtherSide not found, continuing anyway!")
    class pyotherside:
        def atexit(self, *args): pass
        def send(self, *args):
            print("send:", [str(a) for a in args])
    sys.modules["pyotherside"] = pyotherside()

def _sendCompletedSignal(cbObj, *args):
    if cbObj: pyotherside.send('completed', cbObj, *args)

def _sendFailedSignal(cbObj, *args):
    if cbObj: pyotherside.send('failed', cbObj, *args)

def handle_exception(func=None, cbObjName=None):
    import functools
    if not func:
        return functools.partial(handle_exception, cbObjName=cbObjName)
    @functools.wraps(func)
    def exception_handler(*args, **kwargs):
        cbObj = None
        if cbObjName:
            try:
                cbObj = args[func.__code__.co_varnames.index(cbObjName)]
            except IndexError:
                cbObj = kwargs[cbObjName]
        try:
            func(*args, **kwargs)
        except exceptionhandler.ClientException as e:
            logger.error("Exception occurred:", e.id, e.msg, cbObj)
            _sendFailedSignal(cbObj, e.id, e.msg)
        except Exception as e:
            logger.error("Unknown exception occurred:", str(e))
            _sendFailedSignal(cbObj, 0, "unknown exception")
            
    return exception_handler

@worker.run_async
@handle_exception(cbObjName='cbObj')
def connect(username, password, cbObj=None):
    _sendCompletedSignal(cbObj, elfcloudclient.connect(username, password))

@worker.run_async    
@handle_exception(cbObjName='cbObj')
def disconnect(cbObj=None):
    _sendCompletedSignal(cbObj, elfcloudclient.disconnect())

@worker.run_async
@handle_exception(cbObjName='cbObj')    
def getSubscription(cbObj=None):
    _sendCompletedSignal(cbObj, elfcloudclient.getSubscriptionInfo())

@worker.run_async
@handle_exception(cbObjName='cbObj')    
def getVaults(cbObj=None):
    _sendCompletedSignal(cbObj, elfcloudclient.listVaults())
