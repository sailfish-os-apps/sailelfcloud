'''
Created on Sep 19, 2016

@author: @author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest
import tempfile
import os.path
import uploader
from os.path import basename
import elfcloudclient
import exceptionhandler

USERNAME = "xxxx" # Set proper username
PASSWORD = "xxxx" # Set proper password

VALID_PARENTID = 687590
INVALID_PARENTID = -1

class Test_uploader_network(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        elfcloudclient.connect(USERNAME, PASSWORD)

    @classmethod
    def tearDownClass(cls):
        elfcloudclient.disconnect()


    def test_upload_ValidParentIdGiven_ShouldUploadFileToServer(self):
        with tempfile.NamedTemporaryFile('w+') as tf:
            tf.write("some data")
            tf.flush()
            elfcloudclient.upload(VALID_PARENTID, basename(tf.name), tf.name)

    def test_upload_InvalidParentIdGiven_ShouldRaiseExcpetion(self):
        with tempfile.NamedTemporaryFile('w+') as tf:
            tf.write("some data")
            tf.flush()
            self.assertRaises(exceptionhandler.ClientException,
                              elfcloudclient.upload, INVALID_PARENTID, basename(tf.name), tf.name)

    def test_upload_NoFileGiven_ShouldRaiseExcpetion(self):
            self.assertRaises(exceptionhandler.ClientException,
                              elfcloudclient.upload, VALID_PARENTID, None, "filename")

    def test_upload_InvalidFileGiven_ShouldRaiseExcpetion(self):
            self.assertRaises(exceptionhandler.ClientException,
                              elfcloudclient.upload, VALID_PARENTID, "None", "filename")

    def test_upload_EmptyFileGiven_ShouldRaiseExcpetion(self):
        with tempfile.NamedTemporaryFile('w+') as tf:
            self.assertRaises(exceptionhandler.ClientException,
                              elfcloudclient.upload, VALID_PARENTID, basename(tf.name), tf.name)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()