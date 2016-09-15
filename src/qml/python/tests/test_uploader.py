'''
Created on Sep 15, 2016

@author: teemu
'''
import unittest
import unittest.mock
import threading
import uploader


class TestUploader(unittest.TestCase):

    LOCK = threading.Semaphore(0)

    def setUp(self):
        TestUploader.LOCK = threading.Semaphore(0)

    def tearDown(self):
        pass

    @staticmethod
    def _myCallback():
        pass
    
    @staticmethod
    def _sideEffectRelease(*args):
        TestUploader.LOCK.release()
        
    @staticmethod
    def _sideEffectAcquire():
        TestUploader.LOCK.acquire()

    @unittest.mock.patch('uploader.elfCloudAdapter.storeDataItem')
    def testName(self, mock_storeDataItem):
        mock_storeDataItem.side_effect = TestUploader._sideEffectRelease
        uploader.upload("localPath", "remoteParentId", "remoteName", "key", TestUploader._myCallback)
        TestUploader._sideEffectAcquire()
        mock_storeDataItem.assert_called_with(TestUploader._myCallback, "remoteParentId", "remoteName", "localPath")


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
