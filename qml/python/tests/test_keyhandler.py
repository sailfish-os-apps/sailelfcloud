'''
Created on Jun 21, 2016

@author: teemu
'''
import unittest
import tempfile
import shutil
import keyhandler


class Test(unittest.TestCase):


    def setUp(self):
        self.configLocation = tempfile.mkdtemp()
        keyhandler.init(self.configLocation)


    def tearDown(self):
        shutil.rmtree(self.configLocation, ignore_errors=True)
        pass


    def test_storeKeyAndExportAndReadFromFile_ShouldReturnSameKey(self):
        key = {"name":"name", "description":"descr",
               "key":"123456ABCDEF", "iv":"ABCDEF0123456789",
               "hash":"1234567", "mode":"CFB8", "type":"AES128"}
        keyhandler.storeKey(key["name"], key["description"],
                            key["key"], key["iv"],
                            key["hash"], key["mode"], key["type"])
        
        pathToKey = keyhandler.exportKeyToDir("1234567", self.configLocation)
        pathToKey = keyhandler.exportKeyToDir("1234567", self.configLocation)
        keyFromFile = keyhandler.readKeyInfoFromFile(pathToKey)
        self.assertDictContainsSubset(key, keyFromFile)
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()