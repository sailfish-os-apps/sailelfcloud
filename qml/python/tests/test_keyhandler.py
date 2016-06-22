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
        self.configLocation = "./" #tempfile.mkdtemp()
        keyhandler.init(self.configLocation)


    def tearDown(self):
        #shutil.rmtree(self.configLocation, ignore_errors=True)
        pass


    def test_storeKey(self):
        keyhandler.storeKey(name="name", description="descr",
                            key="123456ABCDEF", iv="ABCDEF0123456789",
                            hash="1234567")
        keyhandler.storeKey(name="name2", description="descr",
                            key="123456ABCDEF", iv="ABCDEF0123456789",
                            hash="123456723232")
        print(keyhandler.getKey("123456723232"))
        print(keyhandler.getKeys())


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()