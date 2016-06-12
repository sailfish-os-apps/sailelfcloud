'''
Created on Apr 30, 2016

@author: teemu
'''

"""Depends on pyaes and elfcloud weasel."""

import unittest
import tempfile, filecmp, os
import elfCloudAdapter

# Set your own username and password
USERNAME=""
PASSWORD=""

def setUpModule():
    elfCloudAdapter.connect(USERNAME, PASSWORD)

def tearDownModule():
    elfCloudAdapter.disconnect()


class Test(unittest.TestCase):


    def setUp(self):
        self.assertTrue(elfCloudAdapter.isConnected(), "Client connection has failed")
        self.vaultId = elfCloudAdapter.addVault("ut_test_vault").id
        self.clusterId = elfCloudAdapter.addCluster(self.vaultId, "ut_test_cluster").id

    def tearDown(self):
        elfCloudAdapter.removeCluster(self.clusterId)
        elfCloudAdapter.removeVault(self.vaultId)


    def test_listVaults_ShouldReturnAllVaults(self):
        vaults = elfCloudAdapter.listVaults()
               
        for v in vaults:
            if (v['name'] == 'ut_test_vault'):
                self.assertEqual(self.vaultId, v['id'])
                return
            
        self.fail("Failed to find expeted vault")

    def test_storeDataItems(self):
        localTempFile1 = open("test_file_from_ut_1.txt", "w")
        localTempFile1.write("test data written by unit test")
        localTempFile1.close()
        localTempFile2 = open("test_file_from_ut_2.bin", "wb")
        localTempFile2.write(b"tes\0\0t data\0written by unit test\0") # binary file requires byte objects hence b"
        localTempFile2.close()

        elfCloudAdapter.storeDataItems(self.clusterId, [(localTempFile1.name,"test_file_from_ut_1.txt"),
                                                        (localTempFile2.name,"test_file_from_ut_2.bin")])        
        elfCloudAdapter.waitForRunningTasksCompleted()
        
        elfCloudAdapter.removeDataItem(self.clusterId, "test_file_from_ut_1.txt")
        elfCloudAdapter.removeDataItem(self.clusterId, "test_file_from_ut_2.bin")
        os.remove(localTempFile1.name)
        os.remove(localTempFile2.name)
        
    def test_setDataItemInfo(self):
        tf = tempfile.NamedTemporaryFile("w", delete=False);
        tf.write("aa")
        tf.close()
        elfCloudAdapter.storeDataItem(self.clusterId, "test_file_for_dataitem_info.txt", tf.name);
        elfCloudAdapter.waitForRunningTasksCompleted()
        elfCloudAdapter.updateDataItem(self.clusterId, "test_file_for_dataitem_info.txt", "New description", ["tag1", "tag 2"])
        dataiteminfo = elfCloudAdapter.getDataItemInfo(self.clusterId, "test_file_for_dataitem_info.txt")
        self.assertEqual("test_file_for_dataitem_info.txt", dataiteminfo['name'])
        self.assertEqual("New description", dataiteminfo['description'])        
        self.assertListEqual(["tag1", "tag 2"], dataiteminfo['tags'])
        os.remove(tf.name)

    def test_storeAndFetchLargeDataItem(self):
        localTempFile1 = open("large_test_file_from_ut_1.bin", "wb")
        localTempFile1.write(bytes(range(256)) * 4 * 1000 * 3)
        localTempFile1.close()
        
        elfCloudAdapter.storeDataItems(self.clusterId, [(localTempFile1.name,"large_test_file_from_ut_1.bin")])        
        elfCloudAdapter.waitForRunningTasksCompleted()
        elfCloudAdapter.fetchDataItem(self.clusterId, "large_test_file_from_ut_1.bin", "output_large_test_file_from_ut_1.bin")
        elfCloudAdapter.waitForRunningTasksCompleted()
        elfCloudAdapter.removeDataItem(self.clusterId, "large_test_file_from_ut_1.bin")
        self.assertTrue(filecmp.cmp(localTempFile1.name, "output_large_test_file_from_ut_1.bin", shallow=False))
        os.remove(localTempFile1.name)
        os.remove("output_large_test_file_from_ut_1.bin")

    
    def test_getSubscriptionInfo(self):
        info = elfCloudAdapter.getSubscriptionInfo()
        print("subscription:", info)
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()