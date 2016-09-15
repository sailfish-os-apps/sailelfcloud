'''
Created on Sep 15, 2016

@author: teemu
'''
import unittest
import unittest.mock
import tasks


class TestTasks(unittest.TestCase):

    EXPECTED_UID_FROM_GET_UID = 1234
    
    @staticmethod
    def _dummyCb():
        pass

    @unittest.mock.patch('uidGenerator.getUid', return_value = EXPECTED_UID_FROM_GET_UID)
    def test_Task_ShouldGetUid(self, mock_getUid):
        t = tasks.Task(TestTasks._dummyCb)
        self.assertEqual(self.EXPECTED_UID_FROM_GET_UID, t.uid)
        self.assertEqual(TestTasks._dummyCb, t.cb)

    def test_Task_UidAndCbShouldBeReadOnly(self):
        t = tasks.Task(TestTasks._dummyCb)
        
        with self.assertRaises(AttributeError):
            t.cb = 1

        with self.assertRaises(AttributeError):
            t.uid = 1

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
