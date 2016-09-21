'''
Created on Sep 18, 2016

@author: Teemu Ahola [teemuahola7@gmail.com]
'''
import unittest
import unittest.mock
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
        elfcloudadapter.connect("username", "password", "my_cbobj")
        mock_client.assert_called_once_with("username", "password")
        mock_pyotherside.send.assert_called_once_with("completed", "my_cbobj", None)

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.connect", return_value=None)
    def test_connect_Failure_ShouldConnectWithNameAndPassword_ShouldSendFailedSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda username_, password_ : _raise(elfcloudclient.ClientException(123, "exception description")) 
        elfcloudadapter.connect("username", "password", "my_cbobj")
        mock_client.assert_called_once_with("username", "password")
        mock_pyotherside.send.assert_called_once_with("failed", "my_cbobj", 123, "exception description")

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.disconnect", return_value=None)
    def test_disconnect_Success_ShouldDisconnect_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.disconnect("my_cbobj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with("completed", "my_cbobj", None)

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.disconnect", return_value=None)
    def test_disconnect_Failure_ShouldDisconnect_ShouldSendFailedSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda : _raise(elfcloudclient.ClientException(123, "exception description")) 
        elfcloudadapter.disconnect("my_cbobj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with("failed", "my_cbobj", 123, "exception description")

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.getSubscriptionInfo", return_value={'data':'dictionary'})
    def test_getSubscription_Success_ShouldGetSubscription_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.getSubscription("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('completed', 'my_cbObj', {'data':'dictionary'})

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.getSubscriptionInfo")
    def test_getSubscription_Failure_ShouldGetSubscription_ShouldSendFailedSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda : _raise(elfcloudclient.ClientException(123, "exception description"))
        elfcloudadapter.getSubscription("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('failed', 'my_cbObj', 123, 'exception description')

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.listVaults", return_value=[{'valult1':'data'},{'valult2':'data'}])
    def test_getVaults_Success_ShouldGetVaults_ShouldSendCompletedSignal(self, mock_client, mock_pyotherside):
        elfcloudadapter.getVaults("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('completed', 'my_cbObj', [{'valult1':'data'},{'valult2':'data'}])

    @unittest.mock.patch("elfcloudadapter.pyotherside")
    @unittest.mock.patch("elfcloudadapter.elfcloudclient.listVaults")
    def test_getVaults_Failure_ShouldGetVaults_ShouldSendFailedSignal(self, mock_client, mock_pyotherside):
        mock_client.side_effect = lambda : _raise(elfcloudclient.ClientException(123, "exception description")) 
        elfcloudadapter.getVaults("my_cbObj")
        mock_client.assert_called_once_with()
        mock_pyotherside.send.assert_called_once_with('failed', 'my_cbObj', 123, 'exception description')


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
