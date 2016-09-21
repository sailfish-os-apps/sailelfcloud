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
    def _raise(exception):
        raise exception

    @staticmethod
    def _sideEffectRelease(*args):
        TestUploader.LOCK.release()
        
    @staticmethod
    def _sideEffectAcquire(*args):
        TestUploader.LOCK.acquire()

    @unittest.mock.patch('uploader.elfcloudclient.upload')
    def test_upload_ShouldCallElfCloudAdapterAndCallback(self, mock_upload):
        mock_upload.side_effect = TestUploader._sideEffectRelease
        cb = unittest.mock.Mock()
        
        uploader.upload("localPath1", "remoteParentId1", "remoteName1", "key1", cb)
        TestUploader._sideEffectAcquire()
        uploader.wait()
        mock_upload.assert_called_with("remoteParentId1", "remoteName1", "localPath1")
        cb.assert_called_with()

        uploader.upload("localPath2", "remoteParentId2", "remoteName2", "key2", cb)
        TestUploader._sideEffectAcquire()
        uploader.wait()
        mock_upload.assert_called_with("remoteParentId2", "remoteName2", "localPath2")
        cb.assert_called_with()

    @unittest.mock.patch('uploader.elfcloudclient.upload')
    def test_upload_CallbackNotGiven_ShouldOnlyCallElfCloudAdapter(self, mock_upload):
        uploader.upload("localPath1", "remoteParentId1", "remoteName1", "key1")
        uploader.wait()
        mock_upload.assert_called_with("remoteParentId1", "remoteName1", "localPath1")

    @unittest.mock.patch('uploader.elfcloudclient.upload')
    def test_upload_cancel_ShouldNotUploadCancelled(self, mock_upload):
        mock_upload.side_effect = TestUploader._sideEffectAcquire
        uploader.upload("localPath0", "remoteParentId0", "remoteName0", "key0")
        uploader.upload("localPath1", "remoteParentId1", "remoteName1", "key1")
        uidOfTaskToCancel = uploader.upload("localPath2_to_be_cancelled", "remoteParentId2", "remoteName2", "key2")
        uploader.cancel(uidOfTaskToCancel)
        uploader.upload("localPath3", "remoteParentId3", "remoteName3", "key3")
        TestUploader._sideEffectRelease()
        TestUploader._sideEffectRelease()
        TestUploader._sideEffectRelease()
        uploader.wait()
        mock_upload.assert_has_calls([unittest.mock.call("remoteParentId0", "remoteName0", "localPath0"),
                                      unittest.mock.call("remoteParentId1", "remoteName1", "localPath1"),
                                      unittest.mock.call("remoteParentId3", "remoteName3", "localPath3")])

    @unittest.mock.patch('uploader.elfcloudclient.upload')
    def test_upload_Failure_(self, mock_upload):
        mock_upload.side_effect = lambda x_,y_,z_ : self._raise(uploader.elfcloudclient.ClientException())
        cb = unittest.mock.Mock()
        uploader.upload("localPath1", "remoteParentId1", "remoteName1", "key1", cb)
        uploader.wait()
        mock_upload.assert_called_with("remoteParentId1", "remoteName1", "localPath1")
        print(cb.mock_calls)

    
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
