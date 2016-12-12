'''
Created on Dec 12, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest.mock
import threading
import downloader
import uidgenerator


class TestDownloader(unittest.TestCase):

    LOCK = threading.Semaphore(0)

    def setUp(self):
        TestDownloader.LOCK = threading.Semaphore(0)

    def tearDown(self):
        pass

    @staticmethod
    def _sideEffectRelease(*args):
        TestDownloader.LOCK.release()
        
    @staticmethod
    def _sideEffectAcquire(*args):
        TestDownloader.LOCK.acquire()

    @unittest.mock.patch('downloader.elfcloudclient.getDataItemInfo')
    @unittest.mock.patch('downloader.elfcloudclient.download')
    def test_download_cancel_ShouldNotDownloadCancelled(self, mock_download, mock_getInfo):
        mock_download.side_effect = TestDownloader._sideEffectAcquire
        mock_getInfo.return_value = {'size': 100}
        downloader.download("localPath0", "remoteParentId0", "remoteName0", "key0")
        downloader.download("localPath1", "remoteParentId1", "remoteName1", "key1")
        uidOfTaskToCancel = downloader.download("localPath2_to_be_cancelled", "remoteParentId2", "remoteName2", "key2")
        downloader.cancel(uidOfTaskToCancel)
        downloader.download("localPath3", "remoteParentId3", "remoteName3", "key3")
        TestDownloader._sideEffectRelease()
        TestDownloader._sideEffectRelease()
        TestDownloader._sideEffectRelease()
        downloader.wait()
        mock_download.assert_has_calls([unittest.mock.call("remoteParentId0", "remoteName0", "localPath0", None, None, unittest.mock.ANY),
                                        unittest.mock.call("remoteParentId1", "remoteName1", "localPath1", None, None, unittest.mock.ANY),
                                        unittest.mock.call("remoteParentId3", "remoteName3", "localPath3", None, None, unittest.mock.ANY)])

    @unittest.mock.patch('downloader.elfcloudclient.getDataItemInfo')
    @unittest.mock.patch('downloader.elfcloudclient.download')
    def test_download_pause_(self, mock_download, mock_getInfo):
        mock_download.side_effect = TestDownloader._sideEffectAcquire
        mock_getInfo.return_value = {'size': 100}
        downloader.download("localPath0", "remoteParentId0", "remoteName0", "key0")
        uidOfTaskToPause = downloader.download("localPath2_to_be_paused", "remoteParentId2_to_be_paused", "remoteName2", "key2")
        downloader.pause(uidOfTaskToPause)
        downloader.resume(uidOfTaskToPause)
        TestDownloader._sideEffectRelease()
        TestDownloader._sideEffectRelease()
        downloader.wait()
        mock_download.assert_has_calls([unittest.mock.call("remoteParentId0", "remoteName0", "localPath0", None, None, unittest.mock.ANY),
                                        unittest.mock.call("remoteParentId2_to_be_paused", "remoteName2", "localPath2_to_be_paused", None, None, unittest.mock.ANY)])


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()