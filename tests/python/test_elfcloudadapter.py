'''
Created on Sep 18, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''

import unittest.mock
from  unittest.mock import call
import elfcloudclient

# worker.run_asyc is replaced a version which do not run code in thread.
# MUST BE DONE BEFORE IMPORTING elfcloudadapter!
unittest.mock.patch('worker.run_async', lambda x: x).start()

import elfcloudadapter

def _raise(exception):
    '''Helper for raising exception from lambda.'''
    raise exception

class Test_elfcloudadapter(unittest.TestCase):

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.connect",return_value=None)
    def test_connect_Success_ShouldConnectWithNameAndPassword_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.connect("my_cbobj", "username", "password")
        mock_client.assert_called_once_with("username", "password")
        mock_pyotherside.send.assert_called_once_with("completed", "my_cbobj", None)

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.connect", return_value=None)
    def test_connect_InvalidCreditialsGiven_ShouldConnectWithNameAndPassword_ShouldSendExceptionSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda username_, password_ : _raise(elfcloudclient.AuthenticationFailure()) 
        elfcloudadapter.connect("my_cbobj", "username", "password")
        mock_client.assert_called_once_with("username", "password")
        mock_pyotherside.send.assert_has_calls([call("failed", "my_cbobj", 0, "unknown"),
                                                call("exception", 0, "unknown")])

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.connect", return_value=None)
    def test_connect_Failure_ShouldConnectWithNameAndPassword_ShouldSendExceptionSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda username_, password_ : _raise(elfcloudclient.ClientException(123, "exception description")) 
        elfcloudadapter.connect("my_cbobj", "username", "password")
        mock_client.assert_called_once_with("username", "password")
        mock_pyotherside.send.assert_called_once_with("exception", 123, "exception description")

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.disconnect", return_value=None)
    def test_disconnect_Success_ShouldDisconnect_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.disconnect("my_cbobj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with("completed", "my_cbobj", None)

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.disconnect", return_value=None)
    def test_disconnect_Failure_ShouldDisconnect_ShouldSendExceptionSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda : _raise(elfcloudclient.ClientException(123, "exception description")) 
        elfcloudadapter.disconnect("my_cbobj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with("exception", 123, "exception description")

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.getSubscriptionInfo", return_value={'data':'dictionary'})
    def test_getSubscription_Success_ShouldGetSubscription_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.getSubscription("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('completed', 'my_cbObj', {'data':'dictionary'})

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.getSubscriptionInfo")
    def test_getSubscription_Failure_ShouldGetSubscription_ShouldSendExceptionSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda : _raise(elfcloudclient.ClientException(123, "exception description"))
        elfcloudadapter.getSubscription("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('exception', 123, 'exception description')

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.getWhoAmI", return_value={'data':'dictionary'})
    def test_getWhoAmI_Success_ShouldGetWhoAmI_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.getWhoAmI("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('completed', 'my_cbObj', {'data':'dictionary'})

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.getWhoAmI")
    def test_getWhoAmI_Failure_ShouldGetSubscription_ShouldSendExceptionSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda : _raise(elfcloudclient.ClientException(123, "exception description"))
        elfcloudadapter.getWhoAmI("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('exception', 123, 'exception description')

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.listVaults", return_value=[{'valult1':'data'},{'valult2':'data'}])
    def test_listVaults_Success_ShouldGetVaults_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.listVaults("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('completed', 'my_cbObj', [{'valult1':'data'},{'valult2':'data'}])

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.listVaults")
    def test_listVaults_Failure_ShouldGetVaults_ShouldSendExceptionSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda : _raise(elfcloudclient.ClientException(123, "exception description")) 
        elfcloudadapter.listVaults("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('exception', 123, 'exception description')

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.upload")
    def test_upload_Success_(self, mock_client, mock_pyotherside):
        elfcloudadapter.storeDataItem("cbObj", "parentId", "remotename", "filename")
        import time
        time.sleep(1)
        print(mock_client.mock_calls)
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
