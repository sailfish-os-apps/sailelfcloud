'''
Created on Sep 18, 2016

@author: teemu
'''
import unittest
import elfcloudclient

VALID_USERNAME = "xxxx" # Set proper username
VALID_PASSWORD = "xxxx" # Set proper password

INVALID_USERNAME = "invalid_username"
INVALID_PASSWORD = "invalid_password"

def connect(func):
    from functools import wraps
    @wraps(func)
    def _connect(*args, **kwargs):
        elfcloudclient.connect(VALID_USERNAME, VALID_PASSWORD)
        return func(*args, **kwargs)
    return _connect

class Test_elfcloudclient_noMocks(unittest.TestCase):

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
        elfcloudclient.connect(INVALID_USERNAME, INVALID_PASSWORD)
        self.assertFalse(elfcloudclient.isConnected())
        elfcloudclient.connect(VALID_USERNAME, INVALID_PASSWORD)
        self.assertFalse(elfcloudclient.isConnected())       

    def test_getSubscriptionInfo_NotConnected_ShouldRaiseException(self):
        self.assertRaises(Exception, elfcloudclient.getSubscriptionInfo)
        
    @connect
    def test_getSubscriptionInfo_(self):
        self.assertDictContainsSubset({'Status':'active'}, elfcloudclient.getSubscriptionInfo())

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()