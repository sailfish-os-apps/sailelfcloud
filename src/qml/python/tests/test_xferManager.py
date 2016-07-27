'''
Created on Jul 19, 2016

@author: teemu
'''
import unittest
import unittest.mock
import threading
import xferManager


class Test(unittest.TestCase):


    def setUp(self):
        pass


    def tearDown(self):
        pass

    @unittest.mock.patch('xferManager.elfCloudAdapter')
    def test_SubmitDownloadAndUpload_ShouldCallElfCloudAdapter(self, mock_elfCloudAdapter):       
        xferManager.submitDownload("localPath", "remoteParentId", "remoteName", "key", "cbObj")
        xferManager.submitUpload("localPath", "remoteParentId", "remoteName", "key", "cbObj")
        xferManager.waitAllDone()
        
        mock_elfCloudAdapter.fetchDataItem.assert_called_with("cbObj", "remoteParentId", "localPath", "remoteName", "key")
        mock_elfCloudAdapter.storeDataItem.assert_called_with("cbObj", "remoteParentId", "remoteName", "localPath")
        
        xferManager.submitUpload("localPath2", "remoteParentId2", "remoteName2", "key2", "cbObj2")
        xferManager.waitAllDone()

        mock_elfCloudAdapter.storeDataItem.assert_called_with("cbObj2", "remoteParentId2", "remoteName2", "localPath2")

    @unittest.mock.patch('xferManager.elfCloudAdapter')
    def test_SubmitAndPause_ShouldProcessUnpaused(self, mock_elfCloudAdapter):
        lock = threading.Semaphore(0)
        mock_elfCloudAdapter.storeDataItem.side_effect = lambda cbObj_, parentId_, remotename_, filename_: lock.acquire() 
        
        xferManager.submitDownload("localPath", "remoteParentId", "remoteName", "key", "cbObj")
        uid = xferManager.submitUpload("localPath", "remoteParentId", "remoteName", "key", "cbObj")
        xferManager.cancel(uid)
        lock.release()
        xferManager.waitAllDone()
        
        mock_elfCloudAdapter.storeDataItem.assert_called_with("cbObj", "remoteParentId", "remoteName", "localPath")
        mock_elfCloudAdapter.fetchDataItem.assert_called_with("cbObj", "remoteParentId", "localPath", "remoteName", "key")


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()