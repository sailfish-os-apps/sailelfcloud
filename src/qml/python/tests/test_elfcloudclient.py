'''
Created on Sep 17, 2016

@author: teemu
'''
import unittest
import unittest.mock
from unittest.mock import call
import io
import elfcloudclient
import elfcloud

class Test_elfcloudclient(unittest.TestCase):

    @unittest.mock.patch('elfcloudclient.elfcloud.Client')
    def test_connect_disconnect_isConnected_ShouldUseElfCloudApisWithProperParams_ShouldAffectIsConnected(self, mock_client):
        mock_clientObj = mock_client.return_value
        self.assertFalse(elfcloudclient.isConnected())
        
        elfcloudclient.connect("username", "password")
        mock_client.assert_called_once_with(username="username", auth_data="password",
                                            apikey=elfcloudclient.APIKEY,
                                            server_url=elfcloud.utils.SERVER_DEFAULT)
        mock_clientObj.auth.assert_called_once_with()
        mock_clientObj.set_request_size.assert_called_once_with(elfcloudclient.DEFAULT_REQUEST_SIZE_BYTES)
        self.assertTrue(elfcloudclient.isConnected())
        
        elfcloudclient.disconnect()
        self.assertFalse(elfcloudclient.isConnected())

    @staticmethod
    def _raise(exception):
        raise exception

    @unittest.mock.patch('elfcloudclient.elfcloud.Client')
    def test_connect_AuthenticationFailed_ConnectionShouldStayDisconnected(self, mock_client):
        mock_clientObj = mock_client.return_value
        mock_clientObj.auth.side_effect = lambda : Test_elfcloudclient._raise(elfcloud.exceptions.ECAuthException(1,"message"))
        elfcloudclient.connect("username", "password")
        self.assertFalse(elfcloudclient.isConnected())


    TEST_DATA="1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    TEST_DATA_SIZE=len(TEST_DATA)
    READ_SIZE=int(TEST_DATA_SIZE/3)
    EXPECTED_TOTAL_READ_IN_CHUNKS = [i for i in range(READ_SIZE, TEST_DATA_SIZE, READ_SIZE)] + [TEST_DATA_SIZE]
    
    @staticmethod
    def _store_data_SideEffect(parentId,name,fileObj):
        data = fileObj.read(Test_elfcloudclient.READ_SIZE)
        while (data):
            if len(data) > Test_elfcloudclient.READ_SIZE:
                raise Exception("got more data than chunk size")
            elif data not in Test_elfcloudclient.TEST_DATA:
                raise Exception("got upexpected data")
            data = fileObj.read(Test_elfcloudclient.READ_SIZE)
        

    @unittest.mock.patch('elfcloudclient.client')
    @unittest.mock.patch('builtins.open', new_callable=unittest.mock.mock_open)
    @unittest.mock.patch('elfcloudclient.os.path.getsize')
    def test_upload_ShouldAllowReadingInChunks_ShouldCallCbPerChunk(self, mock_getsize, mock_open, mock_client):
        mock_open.return_value.read=io.StringIO(Test_elfcloudclient.TEST_DATA).read
        mock_getsize.return_value = Test_elfcloudclient.TEST_DATA_SIZE
        mock_client.store_data.side_effect = Test_elfcloudclient._store_data_SideEffect
        mock_cb = unittest.mock.Mock()
    
        elfcloudclient.upload(123, "remotename", "filename", mock_cb)
        mock_getsize.assert_called_once_with("filename")
        mock_open.assert_called_once_with("filename", "rb")
        
        EXPECTED_CB_PARAMS = [call(Test_elfcloudclient.TEST_DATA_SIZE,i) for i in Test_elfcloudclient.EXPECTED_TOTAL_READ_IN_CHUNKS]
        mock_cb.assert_has_calls(EXPECTED_CB_PARAMS)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()