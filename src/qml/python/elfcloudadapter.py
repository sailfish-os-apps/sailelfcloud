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
from time import sleep

import elfcloudclient
import uploader
import downloader
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

def _sendExceptionSignal(id_, message):
    pyotherside.send('exception', id_, message)

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
        except elfcloudclient.ClientException as e:
            logger.error("Exception occurred:", e.id, e.msg, cbObj)
            _sendExceptionSignal(e.id, e.msg)
        except Exception as e:
            logger.error("Unknown exception occurred:", str(e))
            _sendExceptionSignal(0, "unknown exception")
            
    return exception_handler

def setEncryption(key, iv):
    elfcloudclient.setEncryption(key, iv)

def clearEncryption():
    elfcloudclient.clearEncryption()
    
@worker.run_async
@handle_exception(cbObjName='cbObj')
def connect(cbObj, username, password):
    try:
        _sendCompletedSignal(cbObj, elfcloudclient.connect(username, password))
    except elfcloudclient.AuthenticationFailure as e:
        _sendFailedSignal(cbObj, e.id, e.msg)
        raise

@worker.run_async    
@handle_exception(cbObjName='cbObj')
def disconnect(cbObj):
    _sendCompletedSignal(cbObj, elfcloudclient.disconnect())

def isConnected():
    return elfcloudclient.isConnected()

@worker.run_async
@handle_exception(cbObjName='cbObj')    
def getSubscription(cbObj):
    _sendCompletedSignal(cbObj, elfcloudclient.getSubscriptionInfo())

@worker.run_async
@handle_exception(cbObjName='cbObj')    
def getWhoAmI(cbObj):
    _sendCompletedSignal(cbObj, elfcloudclient.getWhoAmI())

@worker.run_async
@handle_exception(cbObjName='cbObj')    
def listVaults(cbObj):
    _sendCompletedSignal(cbObj, elfcloudclient.listVaults())


def _uploadStartedCb(parentId, remoteName, localName, *args):
    pyotherside.send('store-dataitem-started', parentId, remoteName, localName)

def _uploadCompletedCb(cbObj, parentId, remoteName, localName, *args):
    pyotherside.send('store-dataitem-completed', parentId, remoteName, localName)
    _sendCompletedSignal(cbObj)

def _uploadFailedCb(cbObj, parentId, remoteName, localName, exception):
    pyotherside.send('store-dataitem-failed', parentId, remoteName, localName, {'id':int(exception.id), 'msg':exception.msg})
    _sendFailedSignal(cbObj)

def _uploadChunkCb(parentId, remoteName, localName, totalSize, totalSizeStored):
    pyotherside.send('store-dataitem-chunk', parentId, remoteName, localName, totalSize, totalSizeStored)

@handle_exception(cbObjName='cbObj')    
def storeDataItem(cbObj, parentId, remotename, filename):
    uploader.upload(filename, parentId,
                    remotename, None,
                    lambda *args : _uploadStartedCb(parentId, remotename, filename, *args),
                    lambda *args : _uploadCompletedCb(cbObj, parentId, remotename, filename, *args),
                    lambda totalSize, totalSizeStored : _uploadChunkCb(parentId, remotename, filename, totalSize, totalSizeStored),
                    lambda exception : _uploadFailedCb(cbObj, parentId, remotename, filename, exception))

@handle_exception(cbObjName='cbObj')
def cancelStoreDataItem(cbObj, uid):
    uploader.cancel(int(uid))

@handle_exception(cbObjName='cbObj')
def pauseStoreDataItem(cbObj, uid):
    uploader.pause(int(uid))

@handle_exception(cbObjName='cbObj')
def resumeStoreDataItem(cbObj, uid):
    uploader.resume(int(uid))

def _downloadStartedCb(parentId, remoteName, localName, *args):
    pyotherside.send('fetch-dataitem-started', parentId, remoteName, localName)

def _downloadCompletedCb(cbObj, parentId, remoteName, localName, *args):
    pyotherside.send('fetch-dataitem-completed', parentId, remoteName, localName)
    _sendCompletedSignal(cbObj)

def _downloadFailedCb(cbObj, parentId, remoteName, localName, exception):
    pyotherside.send('fetch-dataitem-failed', parentId, remoteName, localName, {'id':int(exception.id), 'msg':exception.msg})
    _sendFailedSignal(cbObj)

def _downloadChunkCb(parentId, remoteName, localName, totalSize, totalSizeStored):
    pyotherside.send('fetch-dataitem-chunk', parentId, remoteName, localName, totalSize, totalSizeStored)

@handle_exception(cbObjName='cbObj')    
def fetchDataItem(cbObj, parentId, remotename, filename):
    downloader.download(filename, parentId,
                        remotename, None,
                        lambda *args : _downloadStartedCb(parentId, remotename, filename, *args),
                        lambda *args : _downloadCompletedCb(cbObj, parentId, remotename, filename, *args),
                        lambda totalSize, totalSizeFetched : _downloadChunkCb(parentId, remotename, filename, totalSize, totalSizeFetched),
                        lambda exception : _downloadFailedCb(cbObj, parentId, remotename, filename, exception))

@handle_exception(cbObjName='cbObj')
def cancelFetchDataItem(cbObj, uid):
    downloader.cancel(int(uid))

@handle_exception(cbObjName='cbObj')
def pauseFetchDataItem(cbObj, uid):
    downloader.pause(int(uid))

@handle_exception(cbObjName='cbObj')
def resumeFetchDataItem(cbObj, uid):
    downloader.resume(int(uid))

@handle_exception(cbObjName='cbObj')    
def listStores(cbObj):
    uploader.listAll(lambda uploads : _sendCompletedSignal(cbObj, uploads))

@handle_exception(cbObjName='cbObj')    
def listFetches(cbObj):
    downloader.listAll(lambda downloads : _sendCompletedSignal(cbObj, downloads))
    
@worker.run_async
@handle_exception(cbObjName='cbObj')    
def listContent(cbObj, parentId):
    _sendCompletedSignal(cbObj, elfcloudclient.listContent(parentId))

@worker.run_async
@handle_exception(cbObjName='cbObj')
def getDataItemInfo(cbObj, parentId, name):
    _sendCompletedSignal(cbObj, elfcloudclient.getDataItemInfo(parentId, name))

@worker.run_async
@handle_exception(cbObjName='cbObj')
def removeDataItem(cbObj, parentId, name):
    _sendCompletedSignal(cbObj, elfcloudclient.removeDataItem(parentId, name))

@worker.run_async
@handle_exception(cbObjName='cbObj')
def renameDataItem(cbObj, parentId, oldName, newName):
    _sendCompletedSignal(cbObj, elfcloudclient.renameDataItem(parentId, oldName, newName))

@worker.run_async
@handle_exception(cbObjName='cbObj')
def addVault(cbObj, name):
    _sendCompletedSignal(cbObj, elfcloudclient.addVault(name))

@worker.run_async
@handle_exception(cbObjName='cbObj')
def removeVault(cbObj, vaultId):
    _sendCompletedSignal(cbObj, elfcloudclient.removeVault(vaultId))

@worker.run_async
@handle_exception(cbObjName='cbObj')
def addCluster(cbObj, parentId, name):
    _sendCompletedSignal(cbObj, elfcloudclient.addCluster(parentId, name))
    
@worker.run_async
@handle_exception(cbObjName='cbObj')
def removeCluster(cbObj, clusterId):
    _sendCompletedSignal(cbObj, elfcloudclient.removeCluster(clusterId))

@worker.run_async
def setProperty(cbObj, name, data):
    try:
        _sendCompletedSignal(cbObj, elfcloudclient.setProperty(name, data.encode()))
    except elfcloudclient.ClientException as e:
        _sendFailedSignal(cbObj, e.id, e.msg)
    
@worker.run_async
def getProperty(cbObj, name):
    try:
        sleep(1)
        _sendCompletedSignal(cbObj, elfcloudclient.getProperty(name).decode('utf-8'))
    except elfcloudclient.NotConnected as e:
        _sendFailedSignal(cbObj, e.id, e.msg)
    except elfcloudclient.ClientException as e:
        _sendCompletedSignal(cbObj, None)
