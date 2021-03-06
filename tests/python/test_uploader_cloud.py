'''
Created on Sep 19, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest.mock
from unittest.mock import call
import tempfile
from os.path import basename
from contextlib import contextmanager
import elfcloudclient
import uploader
from . import ut_username, ut_password

USERNAME = ut_username
PASSWORD = ut_password

VALID_PARENTID = 687590
INVALID_PARENTID = -1

@contextmanager
def uploadTestFile(data):
    EXPECTED_CHUNKS = [i_ for i_ in range(elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES, len(data), \
                                      elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES)] + [len(data)]

    startCb = unittest.mock.Mock()
    completedCb = unittest.mock.Mock()
    chunkCb = unittest.mock.Mock()
    failedCb = unittest.mock.Mock()
    
    with tempfile.NamedTemporaryFile('wb') as tf:
        tf.write(data)
        tf.flush()
        remoteName = basename(tf.name)
        uploader.upload(tf.name, VALID_PARENTID, remoteName, key=None, startCb=startCb,
                        completedCb=completedCb, chunkCb=chunkCb, failedCb=failedCb)
        yield
        elfcloudclient.removeDataItem(VALID_PARENTID, remoteName)
        
    startCb.assert_called_once_with()
    completedCb.assert_called_once_with()
    chunkCb.assert_has_calls([call(len(data),i_) for i_ in EXPECTED_CHUNKS])
    failedCb.assert_not_called()

class Test_uploader_cloud(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        elfcloudclient.connect(USERNAME, PASSWORD)

    @classmethod
    def tearDownClass(cls):
        elfcloudclient.disconnect()


    def test_upload_wait_ShouldUploadFileToServer_ShouldWaitUntilUploadCompleted(self):
        DATA = bytes(range(256)) * 4 * 1000 * 1
        with uploadTestFile(DATA):
            uploader.wait() 

    def test_upload_ManyFilesGiven_wait_ShouldUploadFileToServer_ShouldWaitUntilUploadCompleted(self):
        DATA1 = bytes(range(256)) * 4 * 1000 * 1
        with uploadTestFile(DATA1):
            DATA2 = bytes(range(256)) * 4 * 1000 * 1
            with uploadTestFile(DATA2):
                uploader.wait()

    def test_upload_ManyFilesGiven_cancel_ShouldNotUploadCancelled(self):
        DATA1 = bytes(range(256)) * 4 * 1000 * 2
        with uploadTestFile(DATA1):
            DATA2 = bytes(range(256)) * 4 * 1000 * 1
            with uploadTestFile(DATA2):
                uploader.wait()

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
