'''
Created on Apr 30, 2016

@author: teemu
'''

"""Depends on pyaes and elfcloud weasel."""

import unittest
import tempfile
import elfCloudAdapter

# Set your own username and password
USERNAME="unittestuser"
PASSWORD="utyghK!8"

def setUpModule():
    elfCloudAdapter.connect(USERNAME, PASSWORD)

def tearDownModule():
    elfCloudAdapter.disconnect()


class Test(unittest.TestCase):


    def setUp(self):
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

    @unittest.skip("")
    def test_storeDataItem_TextFile(self):
        localTempFile = tempfile.NamedTemporaryFile("r+")        
        localTempFile.write("test data written by unit test")
        localTempFile.flush()
        result = elfCloudAdapter.storeDataItem(self.clusterId, "test_file_from_ut.txt", localTempFile.name)
        localTempFile.close()
        elfCloudAdapter.removeDataItem(self.clusterId, "test_file_from_ut.txt")

    @unittest.skip("")
    def test_storeDataItem_BinFile(self):
        localTempFile = tempfile.NamedTemporaryFile("rb+")        
        localTempFile.write(b"tes\0\0t data\0written by unit test\0") # binary file requires byte objects hence b"
        localTempFile.flush()
        result = elfCloudAdapter.storeDataItem(self.clusterId, "test_bin_file_from_ut.bin", localTempFile.name)
        localTempFile.close()
        elfCloudAdapter.removeDataItem(self.clusterId, "test_bin_file_from_ut.bin")

    def test_storeDataItems(self):
        localTempFile1 = tempfile.NamedTemporaryFile("r+", delete=False)        
        localTempFile1.write("test data written by unit test")
        localTempFile1.flush()
        localTempFile2 = tempfile.NamedTemporaryFile("rb+", delete=False)        
        localTempFile2.write(b"tes\0\0t data\0written by unit test\0") # binary file requires byte objects hence b"
        localTempFile2.flush()
        localTempFile1.close()
        localTempFile2.close()

        elfCloudAdapter.storeDataItems(self.clusterId, [(localTempFile1.name,"test_file_from_ut_1.txt"),
                                                        (localTempFile2.name,"test_file_from_ut_2.txt")])        
        content = elfCloudAdapter.listContent(self.clusterId)
        print ("content:", content)
               
        elfCloudAdapter.updateDataItem(self.clusterId, "test_file_from_ut_1.txt", "New description", ["tag1", "tag 2"])
        dataiteminfo = elfCloudAdapter.getDataItemInfo(self.clusterId, "test_file_from_ut_1.txt")
        print ("dataitem info:", dataiteminfo)
                
        elfCloudAdapter.removeDataItem(self.clusterId, "test_file_from_ut_1.txt")
        elfCloudAdapter.removeDataItem(self.clusterId, "test_file_from_ut_2.txt")


    @unittest.skip("")
    def test_fetchDataItem_readFile_TextFileGiven_ShouldReturnValidTypeAndString(self):
        filename = elfCloudAdapter.fetchDataItem(self.clusterId, "file_with_data_1.txt", None)
        fileContent = elfCloudAdapter.readFile(filename)
        self.assertEqual("text", fileContent[0])
        self.assertEqual("The data of this file\n", fileContent[1])

    @unittest.skip("")
    def test_fetchDataItem_readFile_BinaryFileGiven_ShouldReturnValidTypeAndHexdump(self):
        filename = elfCloudAdapter.fetchDataItem(self.clusterId, "binary_file.bin", None)
        fileContent = elfCloudAdapter.readFile(filename)
        self.assertEqual("bin", fileContent[0])
        print (fileContent)
    
    
    def test_getSubscriptionInfo(self):
        info = elfCloudAdapter.getSubscriptionInfo()
        print(info)
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()