'''
Created on Apr 30, 2016

@author: teemu
'''
import unittest
import tempfile
import elfCloudAdapter

# Set your own username and password
USERNAME=""
PASSWORD=""

class Test(unittest.TestCase):


    def setUp(self):
        self.assertTrue(elfCloudAdapter.connect(USERNAME, PASSWORD))
        self.vaultId = elfCloudAdapter.addVault("ut_test_vault").id

    def tearDown(self):
        elfCloudAdapter.removeVault(self.vaultId)
        elfCloudAdapter.disconnect()


    def test_listVaults_ShouldReturnAllVaults(self):
        vaults = elfCloudAdapter.listVaults()
               
        for v in vaults:
            if (v['name'] == 'ut_test_vault'):
                self.assertEqual(self.vaultId, v['id'])
                return
            
        self.fail("Failed to find expeted vault")

    def test_storeDataItem_TextFile(self):
        localTempFile = tempfile.NamedTemporaryFile("r+")        
        localTempFile.write("test data written by unit test")
        localTempFile.flush()
        result = elfCloudAdapter.storeDataItem(454835, "test_file_from_ut.txt", localTempFile.name)
        localTempFile.close()
        elfCloudAdapter.removeDataItem(454835, "test_file_from_ut.txt")

    def test_storeDataItem_BinFile(self):
        localTempFile = tempfile.NamedTemporaryFile("rb+")        
        localTempFile.write(b"tes\0\0t data\0written by unit test\0") # binary file requires byte objects hence b"
        localTempFile.flush()
        result = elfCloudAdapter.storeDataItem(454835, "test_bin_file_from_ut.bin", localTempFile.name)
        localTempFile.close()
        elfCloudAdapter.removeDataItem(454835, "test_bin_file_from_ut.bin")

    def test_storeDataItems(self):
        localTempFile1 = tempfile.NamedTemporaryFile("r+")        
        localTempFile1.write("test data written by unit test")
        localTempFile1.flush()
        localTempFile2 = tempfile.NamedTemporaryFile("rb+")        
        localTempFile2.write(b"tes\0\0t data\0written by unit test\0") # binary file requires byte objects hence b"
        localTempFile2.flush()        
        elfCloudAdapter.storeDataItems(454835, [(localTempFile1.name,"test_file_from_ut_1.txt"),
                                                (localTempFile2.name,"test_file_from_ut_2.txt")])
        localTempFile1.close()
        localTempFile2.close()
        elfCloudAdapter.removeDataItem(454835, "test_file_from_ut_1.txt")
        elfCloudAdapter.removeDataItem(454835, "test_file_from_ut_2.txt")


    def test_listContent_ShouldReturnClustersAndDataItems(self):
        content = elfCloudAdapter.listContent(454835)
        print (content)

    def test_fetchDataItem_readFile_TextFileGiven_ShouldReturnValidTypeAndString(self):
        filename = elfCloudAdapter.fetchDataItem(454835, "file_with_data_1.txt", None)
        fileContent = elfCloudAdapter.readFile(filename)
        self.assertEqual("text", fileContent[0])
        self.assertEqual("The data of this file\n", fileContent[1])

    def test_fetchDataItem_readFile_BinaryFileGiven_ShouldReturnValidTypeAndHexdump(self):
        filename = elfCloudAdapter.fetchDataItem(454835, "binary_file.bin", None)
        fileContent = elfCloudAdapter.readFile(filename)
        self.assertEqual("bin", fileContent[0])
        print (fileContent)
        
    def test_getSubscriptionInfo(self):
        info = elfCloudAdapter.getSubscriptionInfo()
        print(info)
        
    def test_removeCluster_removeVault(self):
        cluster = elfCloudAdapter.addCluster(self.vaultId, "ut_test_cluster")
        elfCloudAdapter.removeCluster(cluster.id)


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()