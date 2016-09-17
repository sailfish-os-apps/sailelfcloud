'''
Created on Sep 17, 2016

@author: teemu
'''
import unittest
import unittest.mock
import elfcloudclient
import elfcloud

class Test_elfcloudclient(unittest.TestCase):

    @unittest.skip("reason")
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
    def side(*args):
        print(*args)

    TEST_DATA="1234567890abcdefghijklmnopqrstuvwxyz"

    @unittest.mock.patch('elfcloudclient.client')
    @unittest.mock.patch('elfcloudclient.open', new_callable=unittest.mock.mock_open(read_data=TEST_DATA), create=True)
    @unittest.mock.patch('elfcloudclient.os.path.getsize')
    def test_upload(self, mock_getsize, mock_open, mock_client):
        mock_clientObj = mock_client.return_value
        mock_fileobj = mock_open.return_value
        mock_getsize.return_value = len(Test_elfcloudclient.TEST_DATA)
        mock_client.store_data.side_effect = lambda parentId,name,fileObj : fileObj.read(len(Test_elfcloudclient.TEST_DATA))
        elfcloudclient.upload(123, "remotename", "filename", "chunkCb")
        mock_getsize.assert_called_once_with("filename")
        mock_open.assert_called_once_with("filename", "rb")        
        print(mock_open.mock_calls, mock_client.mock_calls)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()