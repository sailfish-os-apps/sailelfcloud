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
import filecmp
from contextlib import contextmanager
import elfcloudclient
from . import ut_username, ut_password

VALID_USERNAME = ut_username
VALID_PASSWORD = ut_password

INVALID_USERNAME = "invalid_username"
INVALID_PASSWORD = "invalid_password"

TEST_VAULT_NAME = 'unittest' # Must exist in cloud
TEST_VAULT_ID = 687590 # Set according to the vault in cloud

VALID_PARENTID = TEST_VAULT_ID
INVALID_PARENTID = -1

def removeAllDataItemsFromContainer(containerId):
    for i in elfcloudclient.listContent(containerId):
        if i['type'] == 'dataitem':
            elfcloudclient.removeDataItem(containerId, i['name'])
        else:
            elfcloudclient.removeCluster(i['id'])

def setUpModule():
    elfcloudclient.connect(VALID_USERNAME, VALID_PASSWORD)

def tearDownModule():
    removeAllDataItemsFromContainer(TEST_VAULT_ID)
    elfcloudclient.disconnect()

class Test_connection_cloud(unittest.TestCase):

    def setUp(self):
        elfcloudclient.disconnect() # Do disconnect since we will test connections    

    def tearDown(self):
        elfcloudclient.connect(VALID_USERNAME, VALID_PASSWORD) # Leave connected state    

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


class Test_subscription_cloud(unittest.TestCase):

    def tearDown(self):
        elfcloudclient.connect(VALID_USERNAME, VALID_PASSWORD) # Leave connected state since one test does disconnect
    
    def test_getSubscriptionInfo_NotConnected_ShouldRaiseException(self):
        elfcloudclient.disconnect()
        self.assertRaises(Exception, elfcloudclient.getSubscriptionInfo)

    def test_getSubscriptionInfo_ShouldReturnValidSubscription(self):
        self.assertDictContainsSubset({'Status':'active'}, elfcloudclient.getSubscriptionInfo())

class Test_upload_download_cloud(unittest.TestCase):

    DATA = bytes(elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES * 3)
    EXPECTED_CHUNKS = [i_ for i_ in range(elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES, len(DATA), \
                                          elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES)] + [len(DATA)]
    
    def test__upload__download__DownloadedFileShouldMatchOriginalUploaded(self):
        chunkCb = unittest.mock.Mock()
        with tempfile.NamedTemporaryFile('wb') as tf:
            tf.write(self.DATA)
            tf.flush()
            uploadSourceFileName = tf.name
            remoteName = basename(tf.name)
            elfcloudclient.upload(VALID_PARENTID, remoteName, uploadSourceFileName, chunkCb)
            EXPECTED_CB_PARAMS = [call(len(self.DATA),i_) for i_ in self.EXPECTED_CHUNKS]
            chunkCb.assert_has_calls(EXPECTED_CB_PARAMS)
            
            with tempfile.NamedTemporaryFile('wb') as tf:
                downloadSourceFileName = tf.name
                elfcloudclient.download(VALID_PARENTID, remoteName, downloadSourceFileName, key=None, chunkCb=chunkCb)
                self.assertTrue(filecmp.cmp(uploadSourceFileName, downloadSourceFileName, shallow=False))
                chunkCb.assert_has_calls(EXPECTED_CB_PARAMS)

    def test__upload__UseCancelCbToSplitUploadMultipleTimesUsingAppendMode_ShouldUploadCorrectly(self):
        CANCELCB_RETURN_VALUES = [False, True, False, False, False]
        currentOffset = 0
        currentRound = 0
        chunkCb = unittest.mock.Mock()

        def cancelCb(completed):
            nonlocal currentOffset, currentRound, CANCELCB_RETURN_VALUES
            rv = CANCELCB_RETURN_VALUES[currentRound]
            currentOffset = completed
            currentRound += 1
            return rv
 

        with tempfile.NamedTemporaryFile('wb', delete=False) as tf:
            tf.write(self.DATA)
            tf.flush()
            uploadSourceFileName = tf.name
            remoteName = basename(tf.name)
        
            while currentOffset < len(self.DATA):
                elfcloudclient.upload(VALID_PARENTID, remoteName, uploadSourceFileName, chunkCb, cancelCb, currentOffset)
            
            EXPECTED_CB_PARAMS = [call(len(self.DATA),i_) for i_ in self.EXPECTED_CHUNKS]
            chunkCb.assert_has_calls(EXPECTED_CB_PARAMS)
            
            with tempfile.NamedTemporaryFile('wb', delete=False) as tf:
                downloadSourceFileName = tf.name
                elfcloudclient.download(VALID_PARENTID, remoteName, downloadSourceFileName, key=None, chunkCb=chunkCb)
                self.assertTrue(filecmp.cmp(uploadSourceFileName, downloadSourceFileName, shallow=False))
                chunkCb.assert_has_calls(EXPECTED_CB_PARAMS)

    def test__upload__InvalidParentIdGiven_ShouldRaiseExcpetion(self):
        with tempfile.NamedTemporaryFile('wb') as tf:
            tf.write(self.DATA)
            tf.flush()
            self.assertRaises(elfcloudclient.ClientException,
                              elfcloudclient.upload, INVALID_PARENTID, basename(tf.name), tf.name)
            
    def test__upload__NoFileGiven_ShouldRaiseExcpetion(self):
            self.assertRaises(elfcloudclient.ClientException,
                              elfcloudclient.upload, VALID_PARENTID, None, "filename")

    def test__upload__InvalidFileGiven_ShouldRaiseExcpetion(self):
            self.assertRaises(elfcloudclient.ClientException,
                              elfcloudclient.upload, VALID_PARENTID, "None", "filename")

    def test__upload__EmptyFileGiven_ShouldRaiseExcpetion(self):
        with tempfile.NamedTemporaryFile('w+') as tf:
            self.assertRaises(elfcloudclient.ClientException,
                              elfcloudclient.upload, VALID_PARENTID, basename(tf.name), tf.name)

class Test_upload_download_encrypted_cloud(unittest.TestCase):

    DATA = bytes(elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES * 3)
    EXPECTED_CHUNKS = [i_ for i_ in range(elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES, len(DATA), \
                                          elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES)] + [len(DATA)]
    
    @classmethod
    def setUpClass(cls):
        KEY = 'd8b31e395774b3f22d753ce88cc2490f2c625fac0c9a737a5566215fd29ec7c7'
        INITIALIZATION_VECTOR = '1fa39269dae695ea75d0fc43064ff883'
        elfcloudclient.setEncryption(KEY, INITIALIZATION_VECTOR)
    
    @classmethod
    def tearDownClass(cls):
        elfcloudclient.clearEncryption()
    
    def test__upload__download__DownloadedFileShouldMatchOriginalUploaded(self):
        chunkCb = unittest.mock.Mock()

        with tempfile.NamedTemporaryFile('wb') as tf:
            tf.write(self.DATA)
            tf.flush()
            uploadSourceFileName = tf.name
            remoteName = basename(tf.name)
            elfcloudclient.upload(VALID_PARENTID, remoteName, uploadSourceFileName, chunkCb)
            EXPECTED_CB_PARAMS = [call(len(self.DATA),i_) for i_ in self.EXPECTED_CHUNKS]
            chunkCb.assert_has_calls(EXPECTED_CB_PARAMS)
            
            with tempfile.NamedTemporaryFile('wb') as tf:
                downloadSourceFileName = tf.name
                elfcloudclient.download(VALID_PARENTID, remoteName, downloadSourceFileName, key=None, chunkCb=chunkCb)
                self.assertTrue(filecmp.cmp(uploadSourceFileName, downloadSourceFileName, shallow=False))
                chunkCb.assert_has_calls(EXPECTED_CB_PARAMS)


@contextmanager
def createRemoteTempFile():
    DATA = bytes(range(256))
    with tempfile.NamedTemporaryFile('wb') as tf:
        tf.write(DATA)
        tf.flush()
        dataItemName = basename(tf.name)
        elfcloudclient.upload(VALID_PARENTID, dataItemName, tf.name)
        yield dataItemName

class Test_dataitems_cloud(unittest.TestCase):

    DATA = bytes(range(256))    

    def test_listContent_getDataItemInfo_updateDataItem_ListedAndModifiedDataItemShouldHaveValidInfo(self):
        with createRemoteTempFile() as dataItemName:
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
            
    def test_removeDataItem_ShouldNotBeInContentList(self):
        with createRemoteTempFile() as dataItemName:
            items = elfcloudclient.listContent(TEST_VAULT_ID)
            self.assertTrue(any(i['name'] == dataItemName for i in items))
            elfcloudclient.removeDataItem(TEST_VAULT_ID, dataItemName)

            items = elfcloudclient.listContent(TEST_VAULT_ID)
            self.assertFalse(any(i['name'] == dataItemName for i in items))
    
    def test_rename_ShouldChangeNameOfDataItem(self):
        with createRemoteTempFile() as dataItemName:
            newDataItemName = dataItemName+"_new_name_prefix"           
            elfcloudclient.renameDataItem(VALID_PARENTID, dataItemName, newDataItemName)

            items = elfcloudclient.listContent(TEST_VAULT_ID)
            self.assertFalse(any(i['name'] == dataItemName for i in items))
            self.assertTrue(any(i['name'] == newDataItemName for i in items))        

class Test_vaults_and_clusters_cloud(unittest.TestCase):

    def test_addVault_listVaults_removeVault_AddedVaultShouldBeListed(self):
        vaultId = elfcloudclient.addVault("new vault")
        self.assertTrue(any(i['name'] == "new vault" and i['id'] == vaultId and i['type'] == "vault" \
                            for i in elfcloudclient.listVaults()))
        
        elfcloudclient.removeVault(vaultId)
        self.assertFalse(any(i['name'] == "new vault" and i['id'] == vaultId and i['type'] == "vault" \
                            for i in elfcloudclient.listVaults()))
        
    def test_addCluster_renameCluster_removeCluster(self):
        clusterId = elfcloudclient.addCluster(TEST_VAULT_ID, "new cluster")
        self.assertTrue(any(i['name'] == "new cluster" and i['type'] == "cluster" \
                            for i in elfcloudclient.listContent(TEST_VAULT_ID)))
        
        elfcloudclient.renameCluster(clusterId, "renamed cluster name")
        self.assertFalse(any(i['name'] == "new cluster" and i['type'] == "cluster" \
                             for i in elfcloudclient.listContent(TEST_VAULT_ID)))
        self.assertTrue(any(i['name'] == "renamed cluster name" and i['type'] == "cluster" \
                            for i in elfcloudclient.listContent(TEST_VAULT_ID)))

        elfcloudclient.removeCluster(clusterId)
        self.assertFalse(any(i['name'] == "new cluster" and i['type'] == "cluster" \
                             for i in elfcloudclient.listContent(TEST_VAULT_ID)))
        self.assertFalse(any(i['name'] == "renamed cluster name" and i['type'] == "cluster" \
                             for i in elfcloudclient.listContent(TEST_VAULT_ID)))
        
    
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
