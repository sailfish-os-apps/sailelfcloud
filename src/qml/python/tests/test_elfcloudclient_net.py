'''
Created on Sep 18, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]

Tests are done in real elfCLOUD server so they expect to have
valid username and password. Also in the server there must be
one vault given in `TEST_VAULT_NAME` variable which is used
by many testcases. The vault ID must be set to `TEST_VAULT_ID`
variable.

'''

import unittest.mock
from unittest.mock import call
import tempfile
from os.path import basename
import elfcloudclient

VALID_USERNAME = "unittestuser" # Set proper username
VALID_PASSWORD = "utyghK!!" # Set proper password

INVALID_USERNAME = "invalid_username"
INVALID_PASSWORD = "invalid_password"

TEST_VAULT_NAME = 'unittest'
TEST_VAULT_ID = 687590

VALID_PARENTID = TEST_VAULT_ID

def connect(func):
    from functools import wraps
    @wraps(func)
    def _connect(*args, **kwargs):
        if not elfcloudclient.isConnected():
            elfcloudclient.connect(VALID_USERNAME, VALID_PASSWORD)
        return func(*args, **kwargs)
    return _connect

def removeAllDataItemsFromContainer(containerId):
    for i in elfcloudclient.listContent(containerId):
        elfcloudclient.removeDataItem(containerId, i['name'])
    

class Test_elfcloudclient_connection_cloud(unittest.TestCase):

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
        self.assertRaises(elfcloudclient.ClientException, elfcloudclient.connect, INVALID_USERNAME, INVALID_PASSWORD)
        self.assertFalse(elfcloudclient.isConnected())
        self.assertRaises(elfcloudclient.ClientException, elfcloudclient.connect, VALID_USERNAME, INVALID_PASSWORD)
        self.assertFalse(elfcloudclient.isConnected())       


class Test_elfcloudclient_subscription_cloud(unittest.TestCase):

    
    def tearDown(self):
        elfcloudclient.disconnect()    

    def test_getSubscriptionInfo_NotConnected_ShouldRaiseException(self):
        self.assertRaises(Exception, elfcloudclient.getSubscriptionInfo)

    @connect
    def test_getSubscriptionInfo_ShouldReturnValidSubscription(self):
        self.assertDictContainsSubset({'Status':'active'}, elfcloudclient.getSubscriptionInfo())

class Test_elfcloudclient_upload_download_cloud(unittest.TestCase):

    DATA = bytes(range(256)) * 4 * 1000 * 1
    EXPECTED_CHUNKS = [i_ for i_ in range(elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES, len(DATA), \
                                          elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES)] + [len(DATA)]
    
    def tearDown(self):
        removeAllDataItemsFromContainer(TEST_VAULT_ID)
        elfcloudclient.disconnect()    

    @connect
    def test_upload(self):
        chunkCb = unittest.mock.Mock()
        with tempfile.NamedTemporaryFile('wb') as tf:
            tf.write(self.DATA)
            tf.flush()
            elfcloudclient.upload(VALID_PARENTID, basename(tf.name), tf.name, chunkCb)
            EXPECTED_CB_PARAMS = [call(len(self.DATA),i_) for i_ in self.EXPECTED_CHUNKS]
            chunkCb.assert_has_calls(EXPECTED_CB_PARAMS)


class Test_elfcloudclient_dataitems_and_vaults_cloud(unittest.TestCase):

    DATA = bytes(range(256))    

    def tearDown(self):
        removeAllDataItemsFromContainer(TEST_VAULT_ID)
        elfcloudclient.disconnect()    

    @connect
    def test_listVaults_TestVaultShouldBeListed(self):
        for vault in elfcloudclient.listVaults():
            if vault['name'] == TEST_VAULT_NAME and vault['type'] == 'vault' and vault['id'] == TEST_VAULT_ID:
                return
        self.fail("not found expected vault")
    
    @connect
    def test_listContent_getDataItemInfo_updateDataItem_ListedAndModifiedDataItemShouldHaveValidInfo(self):
        with tempfile.NamedTemporaryFile('wb') as tf:
            tf.write(self.DATA)
            tf.flush()
            dataItemName = basename(tf.name)
            elfcloudclient.upload(VALID_PARENTID, dataItemName, tf.name)

            items = elfcloudclient.listContent(VALID_PARENTID)
            self.assertTrue(any(i['name'] == dataItemName for i in items))
            self.assertDictContainsSubset({'name':dataItemName,
                                           'encryption':'NONE',
                                           'description':'',
                                           'tags':[]},
                                          elfcloudclient.getDataItemInfo(TEST_VAULT_ID, dataItemName))
            elfcloudclient.updateDataItem(VALID_PARENTID, dataItemName, "description", ["tag1","tag2","tag3"])
            self.assertDictContainsSubset({'name':dataItemName,
                                           'encryption':'NONE',
                                           'description':'description',
                                           'tags':["tag1","tag2","tag3"]},
                                          elfcloudclient.getDataItemInfo(TEST_VAULT_ID, dataItemName))
            
    @connect
    def test_removeDataItem_ShouldNotBeInContentList(self):
        with tempfile.NamedTemporaryFile('wb') as tf:
            tf.write(self.DATA)
            tf.flush()
            dataItemName = basename(tf.name)
            elfcloudclient.upload(VALID_PARENTID, dataItemName, tf.name)
            
            items = elfcloudclient.listContent(TEST_VAULT_ID)
            self.assertTrue(any(i['name'] == dataItemName for i in items))
                
            elfcloudclient.removeDataItem(TEST_VAULT_ID, dataItemName)

            items = elfcloudclient.listContent(TEST_VAULT_ID)
            self.assertFalse(any(i['name'] == dataItemName for i in items))
    
    @connect
    def test_rename(self):
        with tempfile.NamedTemporaryFile('wb') as tf:
            tf.write(self.DATA)
            tf.flush()
            dataItemName = basename(tf.name)
            newDataItemName = dataItemName+"_new_name_prefix"
            elfcloudclient.upload(VALID_PARENTID, dataItemName, tf.name)
            
            elfcloudclient.renameDataItem(VALID_PARENTID, dataItemName, newDataItemName)

            items = elfcloudclient.listContent(TEST_VAULT_ID)
            self.assertFalse(any(i['name'] == dataItemName for i in items))
            self.assertTrue(any(i['name'] == newDataItemName for i in items))        
    
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
