'''
Created on Sep 18, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest
import unittest.mock

# worker.run_asyc is replaced a version which do not run code in thread.
# MUST BE DONE BEFORE IMPORTING elfcloudadapter!
unittest.mock.patch('worker.run_async', lambda x: x).start()

import elfcloudadapter
import exceptionhandler

def _raise(exception):
    '''Helper for raising exception from lambda.'''
    raise exception

class Test_elfcloudadapter(unittest.TestCase):

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.connect")
    def test_connect_Success_ShouldConnectWithNameAndPassword_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.connect("username", "password", "my_cbobj")
        mock_client.assert_called_once_with("username", "password")
        mock_pyotherside.send.assert_called_once_with("completed", "my_cbobj")

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.connect")
    def test_connect_Failure_ShouldConnectWithNameAndPassword_ShouldSendFailedSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda username_, password_ : _raise(exceptionhandler.ClientException(123, "exception description")) 
        elfcloudadapter.connect("username", "password", "my_cbobj")
        mock_client.assert_called_once_with("username", "password")
        mock_pyotherside.send.assert_called_once_with("failed", "my_cbobj", 123, "exception description")

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.disconnect")
    def test_disconnect_Success_ShouldDisconnect_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.disconnect("my_cbobj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with("completed", "my_cbobj")

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.disconnect")
    def test_disconnect_Failure_ShouldDisconnect_ShouldSendFailedSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda : _raise(exceptionhandler.ClientException(123, "exception description")) 
        elfcloudadapter.disconnect("my_cbobj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with("failed", "my_cbobj", 123, "exception description")

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
