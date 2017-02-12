'''
Created on Sep 15, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import unittest.mock
import tasks


class TestTasks(unittest.TestCase):

    EXPECTED_UID_FROM_GET_UID = 1234
    
    @staticmethod
    def _dummyCb1():
        pass

    @staticmethod
    def _dummyCb2():
        pass

    @staticmethod
    def _dummyCb3():
        pass

    @unittest.mock.patch('tasks.uidgenerator.getUid', return_value = EXPECTED_UID_FROM_GET_UID)
    def test_Task_ShouldGetUid(self, mock_getUid):
        t = tasks.Task(startCb=TestTasks._dummyCb1, completedCb=TestTasks._dummyCb2, failedCb=TestTasks._dummyCb3)
        self.assertEqual(self.EXPECTED_UID_FROM_GET_UID, t.uid)
        self.assertEqual(TestTasks._dummyCb1, t.startCb)
        self.assertEqual(TestTasks._dummyCb2, t.completedCb)

    def test_Task_UidAndCbsShouldBeReadOnly(self):
        t = tasks.Task(TestTasks._dummyCb1)
        
        with self.assertRaises(AttributeError):
            t.startCb = 1

        with self.assertRaises(AttributeError):
            t.completedCb = 1

        with self.assertRaises(AttributeError):
            t.uid = 1
            
    def test_Task_Compare_ShouldSupportIntAndSameType(self):
        t1 = tasks.Task()
        t2 = tasks.Task()
        self.assertTrue(t1 == t1.uid)
        self.assertTrue(t2 == t2)
        self.assertFalse(t2 == t1)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
