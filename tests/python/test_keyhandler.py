'''
Created on Jun 21, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest.mock
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
        keyFromFile = keyhandler.readKeyInfoFromFile(pathToKey)
        self.assertDictContainsSubset(key, keyFromFile)
        
    def test_modifyKey_ShouldBeFoundWithNewDetails(self):
        key = {"name":"name2", "description":"descr",
               "key":"12345CDEF", "iv":"ABCD23456789",
               "hash":"1234567890ABCDEF", "mode":"CFB8", "type":"AES128"}
        keyhandler.storeKey(key["name"], key["description"],
                            key["key"], key["iv"],
                            key["hash"], key["mode"], key["type"])
        key["name"] = 'new name'
        key["description"] = 'new description'
        keyhandler.modifyKey(key["hash"], key["name"], key["description"])
        key2 = keyhandler.getKey(key["hash"])
        self.assertDictContainsSubset(key, key2)

    def test_isKeyWithName_ShouldReturnTrueIfKeyWitnNameExists(self):
        key = {"name":"testing isKeyWithName", "description":"descr",
               "key":"111223334444512345CDEF", "iv":"ABCD23456789",
               "hash":"1234567891122332111220ABCDEF", "mode":"CFB8", "type":"AES128"}
        keyhandler.storeKey(key["name"], key["description"],
                            key["key"], key["iv"],
                            key["hash"], key["mode"], key["type"])
        
        self.assertTrue(keyhandler.isKeyWithName(key["name"]))
        self.assertFalse(keyhandler.isKeyWithName("this key should not exist"))

    def test_convertKeyInfo2Json_convertJson2KeyInfo__GivenListOfKeys_WhenConvertedToJsonAndBack_ThenResultIsIdenticalToOriginal(self):
        keys = [{"name": "test name 1", "description": "test descr 1",
               "key": "111223334444512345CDEF", "iv": "ABCD23456789",
               "hash": "1234567891122332111220ABCDEF", "mode": "CFB8", "type": "AES128"},
                {"name": "test name 2", "description": "test descr 2",
                 "key": "111223334444512345CDEF", "iv": "ABCD23456789",
                 "hash": "1234567891122332111220ABCDEF", "mode": "CFB8", "type": "AES128"}
                ]

        convertedKeys = keyhandler.convertJson2KeyInfo(keyhandler.convertKeyInfo2Json(keys))
        pairs = zip(keys, convertedKeys)
        self.assertTrue(any(x != y for x, y in pairs))

    @unittest.mock.patch('keyhandler._getTimestamp')
    def test_mergeKeyrings__GivenUniqueIdenticalAndConflictingKeys_WhenMerged_ThenUniqueOneIdenticalAndConflictingWithRenamedReturned(self, getTimestamp_mock):
        ring1 = [{"name": "test name 1", "description": "test descr 1",
                  "key": "111", "iv": "ABCD",
                  "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 2", "description": "test descr 2",
                  "key": "111", "iv": "ABCD",
                  "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 3", "description": "different key 3",
                  "key": "111", "iv": "ABCD",
                  "hash": "12345", "mode": "CFB8", "type": "AES128"}
                 ]

        ring2 = [{"name": "test name 1", "description": "test descr 1",
                  "key": "111", "iv": "ABCD",
                  "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 3", "description": "test descr 3",
                  "key": "111", "iv": "ABCD",
                  "hash": "12345", "mode": "CFB8", "type": "AES128"}
                 ]

        expectedRing = [
            {'description': 'test descr 1', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD', 'name': 'test name 1'},
            {'description': 'test descr 2', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD', 'name': 'test name 2'},
            {'description': 'different key 3', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD', 'name': 'test name 3 (ts)'},
            {'description': 'test descr 3', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD', 'name': 'test name 3'}]

        getTimestamp_mock.return_value = "ts" # mock timestamp query so that we can do easy validity check
        mergedRing = keyhandler.mergeKeyrings(ring1, ring2)

        self.assertCountEqual(expectedRing, mergedRing)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()