'''
Created on Apr 30, 2016

@author: teemu
'''

"""Depends on pyaes and elfcloud weasel."""

import unittest
import tempfile, filecmp, os
import elfCloudAdapter, worker

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
        self.vaultId = elfCloudAdapter._addVault("ut_test_vault").id
        self.clusterId = elfCloudAdapter._addCluster(self.vaultId, "ut_test_cluster").id

    def tearDown(self):
        elfCloudAdapter.removeVault(None, self.vaultId)
        worker.waitForRunningTasksCompleted()

    def test_listVaults_ShouldReturnAllVaults(self):
        vaults = elfCloudAdapter.listVaults()
               
        for v in vaults:
            if (v['name'] == 'ut_test_vault'):
                self.assertEqual(self.vaultId, v['id'])
                return
            
        self.fail("Failed to find expeted vault")

    def test_setDataItemInfo(self):
        tf = tempfile.NamedTemporaryFile("w", delete=False);
        tf.write("aa")
        tf.close()
        elfCloudAdapter.storeDataItem(None, self.clusterId, "test_file_for_dataitem_info.txt", tf.name);
        worker.waitForRunningTasksCompleted()
        elfCloudAdapter.updateDataItem(self.clusterId, "test_file_for_dataitem_info.txt", "New description", ["tag1", "tag 2"])
        dataiteminfo = elfCloudAdapter.getDataItemInfo(None, self.clusterId, "test_file_for_dataitem_info.txt")
        self.assertEqual("test_file_for_dataitem_info.txt", dataiteminfo['name'])
        self.assertEqual("New description", dataiteminfo['description'])        
        self.assertListEqual(["tag1", "tag 2"], dataiteminfo['tags'])
        os.remove(tf.name)

    def test_storeAndFetchLargeDataItem(self):
        localTempFile1 = open("large_test_file_from_ut_1.bin", "wb")
        localTempFile1.write(bytes(range(256)) * 4 * 1000 * 3)
        localTempFile1.close()
        elfCloudAdapter.storeDataItem(None, self.clusterId, localTempFile1.name, "large_test_file_from_ut_1.bin")        
        worker.waitForRunningTasksCompleted()
        elfCloudAdapter.fetchDataItem(None, self.clusterId, "large_test_file_from_ut_1.bin", "output_large_test_file_from_ut_1.bin")
        worker.waitForRunningTasksCompleted()
        elfCloudAdapter.removeDataItem(None, self.clusterId, "large_test_file_from_ut_1.bin")
        self.assertTrue(filecmp.cmp(localTempFile1.name, "output_large_test_file_from_ut_1.bin", shallow=False))
        os.remove(localTempFile1.name)
        os.remove("output_large_test_file_from_ut_1.bin")

    
    def test_getSubscriptionInfo(self):
        info = elfCloudAdapter.getSubscriptionInfo(None)
        print("subscription:", info)
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()