'''
Created on Sep 15, 2016

@author: teemu
'''
import unittest
import threading
import uidGenerator


class TestUidGenerator(unittest.TestCase):


    def test_getUid_ShouldReturnUniqueId(self):
        self.assertNotEqual(uidGenerator.getUid(), uidGenerator.getUid())
        self.assertNotEqual(uidGenerator.getUid(), uidGenerator.getUid())

    parallelTasks = []
    parallelResults = []

    def async_getUid(self):
        t = threading.Thread(target = lambda : self.parallelResults.append(uidGenerator.getUid()))
        t.start()
        self.parallelTasks.append(t)

    @staticmethod
    def unique_values(g):
        s = set()
        for x in g:
            if x in s: return False
            s.add(x)
        return True

    def test_getUid_Threaded_ShouldReturnUniqueId(self):

        for _ in range(1000):
            self.async_getUid()

        for t in self.parallelTasks:
            t.join()

        self.assertTrue(TestUidGenerator.unique_values(self.parallelResults), "failed to generate unique IDs in parallel")


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
