'''
Created on Jun 4, 2016

@author: teemu
'''

'''Testcases for comparing Crypto AES to pyaes.'''

import unittest
from Crypto.Cipher import AES
import pyaes
import cProfile, pstats


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
            encryptedChunks.append(pyaes_cipher.encrypt(bytearray(c, "utf-8")))
        
        decryptedChunks = []
        for c in encryptedChunks:
            decryptedChunks.append(pycrypto_cipher.decrypt(bytes(c)))
            
        self.assertListEqual(decryptedChunks, [bytes(b, 'utf-8') for b in dataChunks])

    def test_CompareCryptoAESCryptToPyAesDecrypt(self):
        dataChunks = self._createChunks(self.DATA, 8)
        pycrypto_cipher = AES.new(self.KEY, AES.MODE_CFB, self.IV, segment_size=8*8)
        pyaes_cipher = pyaes.AESModeOfOperationCFB(self.KEY, iv=self.IV, segment_size=8)

        encryptedChunks = []        
        for c in dataChunks: 
            encryptedChunks.append(pycrypto_cipher.encrypt(c))

        decryptedChunks = []
        for c in encryptedChunks:
            decryptedChunks.append(pyaes_cipher.decrypt(c))
            
        self.assertListEqual(decryptedChunks, [bytearray(b, 'utf-8') for b in dataChunks])

    def test_PyCryptoPerformance(self):
        data = bytes(range(256)) * 4 * 1000 * 1
        dataChunks = self._createChunks(data, 16)
        pycrypto_cipher = AES.new(self.KEY, AES.MODE_CFB, self.IV, segment_size=8*8)
        pycrypto_decipher = AES.new(self.KEY, AES.MODE_CFB, self.IV, segment_size=8*8)
        
        self.pr = cProfile.Profile()
        self.pr.enable()

        encryptedChunks = []
        for c in dataChunks: 
            encryptedChunks.append(pycrypto_cipher.encrypt(c))

        decryptedChunks = []
        for c in encryptedChunks:
            decryptedChunks.append(pycrypto_decipher.decrypt(c))
            
        sortby = 'cumulative'
        self.pr.disable()
        ps = pstats.Stats(self.pr).sort_stats(sortby)
        ps.print_stats()

        self.assertListEqual(decryptedChunks, dataChunks)


    def test_PyAesPerformance(self):
        data = bytes(range(256)) * 4 * 1000 * 1
        dataChunks = self._createChunks(data, 16)
        pyaes_cipher = pyaes.AESModeOfOperationCFB(self.KEY, iv=self.IV, segment_size=16)
        pyaes_decipher = pyaes.AESModeOfOperationCFB(self.KEY, iv=self.IV, segment_size=16)
        
        self.pr = cProfile.Profile()
        self.pr.enable()

        encryptedChunks = []
        for c in dataChunks: 
            encryptedChunks.append(pyaes_cipher.encrypt(c))

        decryptedChunks = []
        for c in encryptedChunks:
            decryptedChunks.append(pyaes_decipher.decrypt(c))
            
        sortby = 'cumulative'
        self.pr.disable()
        ps = pstats.Stats(self.pr).sort_stats(sortby)
        ps.print_stats()

        self.assertListEqual(decryptedChunks, dataChunks)



if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
