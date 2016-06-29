'''
Created on Apr 30, 2016

@author: teemu
'''

"""Depends on pyaes and elfcloud weasel."""

import unittest.mock
import tempfile, filecmp, os, sys
import worker

# worker.run_asyc is replaced a version which do not run code in thread
unittest.mock.patch('worker.run_async', lambda x: x).start()
import elfCloudAdapter

# Set your own username and password
USERNAME=""
PASSWORD=""

def setUpModule():
    elfCloudAdapter.connect(None, USERNAME, PASSWORD)

def tearDownModule():
    elfCloudAdapter.disconnect(None)

class mock_pyotherside:
    
    sentArgs = None
    
    @staticmethod
    def atexit(*args): pass
    @staticmethod
    def send(signal, *args):
        print("UT:", signal, [str(a) for a in args])
        mock_pyotherside.sentArgs = args


elfCloudAdapter.pyotherside = mock_pyotherside
sys.modules["pyotherside"] = mock_pyotherside()

class Test(unittest.TestCase):

    def setUp(self):
        self.assertTrue(elfCloudAdapter.isConnected(), "Client connection has failed")
        elfCloudAdapter.addVault(None, "ut_test_vault")
        self.vaultId = mock_pyotherside.sentArgs[1]
        elfCloudAdapter.addCluster(None, self.vaultId, "ut_test_cluster")
        self.clusterId = mock_pyotherside.sentArgs[3]

    def tearDown(self):
        elfCloudAdapter.removeVault(None, self.vaultId)

    def test_listVaults_ShouldReturnAllVaults(self):
        elfCloudAdapter.listVaults(None)
        vaults = mock_pyotherside.sentArgs[1]
               
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
        elfCloudAdapter.updateDataItem(self.clusterId, "test_file_for_dataitem_info.txt", "New description", ["tag1", "tag 2"])
        elfCloudAdapter.getDataItemInfo(None, self.clusterId, "test_file_for_dataitem_info.txt")
        dataiteminfo = mock_pyotherside.sentArgs[1]
        print("info", dataiteminfo)
        elfCloudAdapter.listContent(None, self.clusterId)
        content = mock_pyotherside.sentArgs[1]
        print("content", content)
        self.assertEqual("test_file_for_dataitem_info.txt", dataiteminfo['name'])
        self.assertEqual("New description", dataiteminfo['description'])        
        self.assertListEqual(["tag1", "tag 2"], dataiteminfo['tags'])
        os.remove(tf.name)
        
    def test_storeAndFetchLargeDataItem(self):
        localTempFile1 = open("large_test_file_from_ut_1.bin", "wb")
        localTempFile1.write(bytes(range(256)) * 4 * 1000 * 3)
        localTempFile1.close()
        elfCloudAdapter.storeDataItem(None, self.clusterId, localTempFile1.name, "large_test_file_from_ut_1.bin")        
        elfCloudAdapter.fetchDataItem(None, self.clusterId, "large_test_file_from_ut_1.bin", "output_large_test_file_from_ut_1.bin")
        elfCloudAdapter.removeDataItem(None, self.clusterId, "large_test_file_from_ut_1.bin")
        self.assertTrue(filecmp.cmp(localTempFile1.name, "output_large_test_file_from_ut_1.bin", shallow=False))
        os.remove(localTempFile1.name)
        os.remove("output_large_test_file_from_ut_1.bin")

    def test_getSubscriptionInfo(self):
        info = elfCloudAdapter.getSubscriptionInfo(None)
        info = mock_pyotherside.sentArgs[1]
        self.assertTrue(info)
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()