'''
Created on Sep 29, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest.mock
from os.path import basename
from contextlib import contextmanager
import tempfile
import filecmp
import elfcloudclient
import downloader

USERNAME = "xxxx" # Set proper username
PASSWORD = "xxxx" # Set proper password

VALID_PARENTID = 687590
INVALID_PARENTID = -1

@contextmanager
def uploadTestFile(data):
    """Uploads a testfile to cloud with given content."""

    with tempfile.NamedTemporaryFile('wb') as tf:
        tf.write(data)
        tf.flush()
        remoteName = basename(tf.name)
        elfcloudclient.upload(VALID_PARENTID, remoteName, tf.name)
        yield (tf.name, remoteName)
        elfcloudclient.removeDataItem(VALID_PARENTID, remoteName)
                

class Test_downloader_cloud(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        elfcloudclient.connect(USERNAME, PASSWORD)

    @classmethod
    def tearDownClass(cls):
        elfcloudclient.disconnect()

    def _assertFilesEqual(self, path1, path2):
        self.assertTrue(filecmp.cmp(path1, path2))

    def test_download_ShouldDownloadFileSuccesfully(self):
        DATA = bytes(range(256)) * 4 * 1000 * 1
        
        with uploadTestFile(DATA) as (localName,remoteName):
            with tempfile.NamedTemporaryFile('wb') as tf:
                downloader.download(tf.name, VALID_PARENTID, remoteName, key=None,
                                    startCb=None,
                                    completedCb=lambda : self._assertFilesEqual(tf.name, localName),
                                    chunkCb=None)
                downloader.wait()

    def test_download_FileDoesNotExist_ShouldCallFailedCb(self):
        NON_EXISTING_REMOTE_FILE="this_file_does_not_exist_on_cloud"
        failedCb = unittest.mock.Mock()
        with tempfile.NamedTemporaryFile('wb') as tf:
            downloader.download(tf.name, VALID_PARENTID, NON_EXISTING_REMOTE_FILE, key=None,
                                startCb=None, completedCb=None, chunkCb=None,
                                failedCb=failedCb)
            downloader.wait()
        
        failedCb.assert_called_once_with(unittest.mock.ANY)


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
