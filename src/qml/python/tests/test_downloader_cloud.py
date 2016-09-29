'''
Created on Sep 29, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest.mock
from unittest.mock import call
import tempfile
from os.path import basename
from contextlib import contextmanager
import elfcloudclient
import uploader

USERNAME = "xxxx" # Set proper username
PASSWORD = "xxxx" # Set proper password

VALID_PARENTID = 687590
INVALID_PARENTID = -1


class Test_downloader_cloud(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        elfcloudclient.connect(USERNAME, PASSWORD)

    @classmethod
    def tearDownClass(cls):
        elfcloudclient.disconnect()


    def testName(self):
        pass


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
