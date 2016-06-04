'''
Created on Jun 4, 2016

@author: teemu
'''

'''Testcases for comparing Crypto AES to pyaes.'''

import unittest
from Crypto.Cipher import AES
import pyaes

ENC=1
DEC=0

class Test(unittest.TestCase):

    KEY = bytes('12345678901234567890123456789012', 'utf-8')
    IV = bytes('1234567890123456', 'utf-8')
    DATA = "My secret data to encrypt"

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def _createChunks(self, data, chunkSize):
        chunks = ([data[i:i+chunkSize] for i in range(0, len(data), chunkSize)])
        # Pad last chunk
        chunks[-1] = chunks[-1].ljust(chunkSize) 
        return chunks

    def test_ComparePyAesCryptToCryptoAESDecrypt(self):
        dataChunks = self._createChunks(self.DATA, 8)
        pyaes_cipher = pyaes.AESModeOfOperationCFB(self.KEY, iv=self.IV, segment_size=8)
        pycrypto_cipher = AES.new(self.KEY, AES.MODE_CFB, self.IV, segment_size=8*8)

        encryptedChunks = []        
        for c in dataChunks: 
            encryptedChunks.append(pyaes_cipher.encrypt(c))
        
        decryptedChunks = []
        for c in encryptedChunks:
            decryptedChunks.append(str(pycrypto_cipher.decrypt(c), "utf-8"))
            
        self.assertListEqual(decryptedChunks, dataChunks)
        
    def test_CompareCryptoAESCryptToPyAesDecrypt(self):
        dataChunks = self._createChunks(self.DATA, 8)
        pycrypto_cipher = AES.new(self.KEY, AES.MODE_CFB, self.IV, segment_size=8*8)
        pyaes_cipher = pyaes.AESModeOfOperationCFB(self.KEY, iv=self.IV, segment_size=8)

        encryptedChunks = []        
        for c in dataChunks: 
            encryptedChunks.append(pycrypto_cipher.encrypt(c))

        decryptedChunks = []
        for c in encryptedChunks:
            decryptedChunks.append(str(pyaes_cipher.decrypt(c), "utf-8"))
            
        self.assertListEqual(decryptedChunks, dataChunks)


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()