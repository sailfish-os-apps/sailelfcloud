'''
Created on Sep 18, 2016

@author: @author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest
import unittest.mock
from unittest.mock import call
import tempfile
from os.path import basename
import elfcloudclient
import exceptionhandler

VALID_USERNAME = "xxxx" # Set proper username
VALID_PASSWORD = "xxxx" # Set proper password

INVALID_USERNAME = "invalid_username"
INVALID_PASSWORD = "invalid_password"

VALID_PARENTID = 687590

def connect(func):
    from functools import wraps
    @wraps(func)
    def _connect(*args, **kwargs):
        elfcloudclient.connect(VALID_USERNAME, VALID_PASSWORD)
        return func(*args, **kwargs)
    return _connect

class Test_elfcloudclient_network(unittest.TestCase):

    DATA = bytes(range(256)) * 4 * 1000 * 1
    EXPECTED_CHUNKS = [i_ for i_ in range(elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES, len(DATA), \
                                          elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES)] + [len(DATA)]
    
    def tearDown(self):
        elfcloudclient.disconnect()

    def test_connect_disconnect_ValidCreditialsGiven_ShouldConnectSuccesfully(self):
        self.assertFalse(elfcloudclient.isConnected())
        elfcloudclient.connect(VALID_USERNAME, VALID_PASSWORD)
        self.assertTrue(elfcloudclient.isConnected())
        elfcloudclient.disconnect()
        self.assertFalse(elfcloudclient.isConnected())

    @unittest.skip("do not stress official server with invalid creditials")
    def test_connect_InValidCreditialsGiven_ShouldNotConnect(self):
        self.assertFalse(elfcloudclient.isConnected())
        self.assertRaises(exceptionhandler.ClientException, elfcloudclient.connect, INVALID_USERNAME, INVALID_PASSWORD)
        self.assertFalse(elfcloudclient.isConnected())
        self.assertRaises(exceptionhandler.ClientException, elfcloudclient.connect, VALID_USERNAME, INVALID_PASSWORD)
        self.assertFalse(elfcloudclient.isConnected())       

    def test_getSubscriptionInfo_NotConnected_ShouldRaiseException(self):
        self.assertRaises(Exception, elfcloudclient.getSubscriptionInfo)
        
    @connect
    def test_getSubscriptionInfo_(self):
        self.assertDictContainsSubset({'Status':'active'}, elfcloudclient.getSubscriptionInfo())

    @connect
    def test_listVaults(self):
        for vault in elfcloudclient.listVaults():
            if vault['name'] == 'unittest' and vault['type'] == 'vault' and vault['id'] == VALID_PARENTID:
                return
        self.fail("not found expected vault")
        
    @connect
    def test_upload(self):
        chunkCb = unittest.mock.Mock()
        with tempfile.NamedTemporaryFile('wb') as tf:
            tf.write(self.DATA)
            tf.flush()
            elfcloudclient.upload(VALID_PARENTID, basename(tf.name), tf.name, chunkCb)
            EXPECTED_CB_PARAMS = [call(len(self.DATA),i_) for i_ in self.EXPECTED_CHUNKS]
            chunkCb.assert_has_calls(EXPECTED_CB_PARAMS)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()