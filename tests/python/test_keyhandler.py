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
        # In oder to ensure that keys are in the same order in both lists, they are sorted according to key name field
        pairs = zip(sorted(keys, key=lambda _k : _k["name"]), sorted(convertedKeys, key=lambda _k : _k["name"]))
        self.assertTrue(any(x == y for x, y in pairs))

    @unittest.mock.patch('keyhandler._getTimestamp')
    def test_mergeKeyrings__GivenOneIdenticalKey_WhenMerged_ThenTheKeyOnlyOnceInMergedKeyring(self, getTimestamp_mock):
        ring1 = [{"name": "test name 1", "description": "test descr 1", "key": "111", "iv": "ABCD", "hash": "12345",
                  "mode": "CFB8", "type": "AES128"}]
        ring2 = [{"name": "test name 1", "description": "test descr 1", "key": "111", "iv": "ABCD", "hash": "12345",
                  "mode": "CFB8", "type": "AES128"}]

        expectedRing = [
            {'name': 'test name 1', 'description': 'test descr 1', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'}]
        expectedOperations = [
            ('keep', 'test name 1')]

        getTimestamp_mock.return_value = "ts" # mock timestamp query so that we can do easy validity check
        mergedRing,operations = keyhandler.mergeKeyrings(ring1, ring2)

        self.assertCountEqual(expectedRing, mergedRing)
        self.assertListEqual(expectedOperations, operations)

    @unittest.mock.patch('keyhandler._getTimestamp')
    def test_mergeKeyrings__GivenUniqueIdenticalAndConflictingKeys_WhenMerged_ThenUniqueOneIdenticalAndConflictingWithRenamedReturned(self, getTimestamp_mock):
        ring1 = [{"name": "test name 1", "description": "test descr 1", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 2", "description": "test descr 2", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 3", "description": "different key 3", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"}]

        ring2 = [{"name": "test name 1", "description": "test descr 1", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 3", "description": "test descr 3", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"}]

        expectedRing = [
            {'name': 'test name 1', 'description': 'test descr 1', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'},
            {'name': 'test name 2', 'description': 'test descr 2', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'},
            {'name': 'test name 3 (ts)', 'description': 'different key 3', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'},
            {'name': 'test name 3', 'description': 'test descr 3', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'}]
        expectedOperations = [
            ('keep', 'test name 1'),
            ('add',  'test name 2'),
            ('rename', ('test name 3', 'test name 3 (ts)')),
            ('add',  'test name 3')]

        getTimestamp_mock.return_value = "ts" # mock timestamp query so that we can do easy validity check
        mergedRing,operations = keyhandler.mergeKeyrings(ring1, ring2)

        self.assertCountEqual(expectedRing, mergedRing)
        self.assertListEqual(expectedOperations, operations)

    @unittest.mock.patch('keyhandler._getTimestamp')
    def test_mergeJsonKeyrings__GivenUniqueIdenticalAndConflictingKeys_WhenMerged_ThenUniqueOneIdenticalAndConflictingWithRenamedReturned(self, getTimestamp_mock):

        #
        # Note! Testdata is in keyring object (keyinfo) format for convince. It is easier to write than JSON string.
        #

        ring1 = [{"name": "test name 1", "description": "test descr 1", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 2", "description": "test descr 2", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 3", "description": "test descr 3", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"}]

        ring2 = [{"name": "test name 1", "description": "test descr 1", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 3", "description": "different test descr 3", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"},
                 {"name": "test name 4", "description": "test descr 4", "key": "111", "iv": "ABCD", "hash": "12345", "mode": "CFB8", "type": "AES128"}]

        getTimestamp_mock.return_value = "ts" # mock timestamp query so that we can do easy validity check
        jsonRing1 = keyhandler.convertKeyInfo2Json(ring1)
        jsonRing2 = keyhandler.convertKeyInfo2Json(ring2)

        mergedJsonRing,operations = keyhandler.mergeJsonKeyrings(jsonRing1, jsonRing2)

        expectedRing = [
            {'name': 'test name 1', 'description': 'test descr 1', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'},
            {'name': 'test name 2', 'description': 'test descr 2', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'},
            {'name': 'test name 3', 'description': 'different test descr 3', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'},
            {'name': 'test name 3 (ts)', 'description': 'test descr 3', 'type': 'AES128', 'hash': '12345', 'key': '111', 'mode': 'CFB8', 'iv': 'ABCD'},
            {"name": "test name 4", "description": "test descr 4", "type": "AES128", "hash": "12345", "key": "111", "mode": "CFB8", "iv": "ABCD"}]
        expectedOperations = [
            ('add',  'test name 2'),
            ('rename', ('test name 3', 'test name 3 (ts)')),
            ('keep',  'test name 1'),
            ('keep',  'test name 3'),
            ('keep', 'test name 4')]

        mergedRing = keyhandler.convertJson2KeyInfo(mergedJsonRing)

        self.assertCountEqual(expectedRing, mergedRing)
        self.assertCountEqual(expectedOperations, operations)

    def test_CryptedFile(self):

        KEY = 'd8b31e395774b3f22d753ce88cc2490f2c625fac0c9a737a5566215fd29ec7c7'
        INITIALIZATION_VECTOR = '1fa39269dae695ea75d0fc43064ff883'
        DATA = bytes(range(256))

        with keyhandler.CryptedFile("/tmp/test.bin", KEY, INITIALIZATION_VECTOR, "w") as f1:
            f1.write(DATA)

        with keyhandler.CryptedFile("/tmp/test.bin", KEY, INITIALIZATION_VECTOR, "r") as f2:
            data = f2.read(256)

        self.assertEqual(DATA, data)



if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()