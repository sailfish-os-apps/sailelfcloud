'''
Created on Jun 19, 2016

@author: teemu
'''
import unittest

"""Depends on pyaes and elfcloud weasel."""

import unittest.mock
import tempfile, filecmp, os, sys, binascii
import worker

# worker.run_asyc is replaced a version which do not run code in thread
unittest.mock.patch('worker.run_async', lambda x: x).start()
import elfCloudAdapter

# Set your own username and password
USERNAME=""
PASSWORD=""

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
        elfCloudAdapter.connect(None, USERNAME, PASSWORD)
        self.assertTrue(elfCloudAdapter.isConnected(), "Client connection has failed")
        elfCloudAdapter.addVault(None, "ut_test_vault")
        self.vaultId = mock_pyotherside.sentArgs[1]
        elfCloudAdapter.addCluster(None, self.vaultId, "ut_test_cluster_for_encryption")
        self.clusterId = mock_pyotherside.sentArgs[3]
        
    def tearDown(self):        
        elfCloudAdapter.removeVault(None, self.vaultId)
        elfCloudAdapter.disconnect(None)

    def testName(self):
        k = 'd8b31e395774b3f22d753ce88cc2490f2c625fac0c9a737a5566215fd29ec7c7'
        i = '1fa39269dae695ea75d0fc43064ff883'
        elfCloudAdapter.setEncryption(k, i)
        localTempFile1 = open("large_test_file_from_ut_1.bin", "wb")
        localTempFile1.write(bytes(range(256)) * 2 * 1000 * 1)
        localTempFile1.close()
        elfCloudAdapter.storeDataItem(None, self.clusterId, localTempFile1.name, "large_test_file_from_ut_1.bin")
        
        elfCloudAdapter.getDataItemInfo(None, self.clusterId, "large_test_file_from_ut_1.bin")
        dataiteminfo = mock_pyotherside.sentArgs[1]
        print("info", dataiteminfo)
                
        elfCloudAdapter.fetchDataItem(None, self.clusterId, "large_test_file_from_ut_1.bin", "output_large_test_file_from_ut_1.bin")
        self.assertTrue(filecmp.cmp(localTempFile1.name, "output_large_test_file_from_ut_1.bin", shallow=False))
        os.remove(localTempFile1.name)
        os.remove("output_large_test_file_from_ut_1.bin")
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()