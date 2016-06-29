'''
Created on Jun 28, 2016

@author: teemu
'''

import os
 
# from http://stackoverflow.com/questions/183480/is-this-the-best-way-to-get-unique-version-of-filename-w-python
def uniqueFile(fileName):
    counter = 1
    file_name_parts = os.path.splitext(fileName) # returns ('/path/file', '.ext')
    while 1:
        try:
            fd = os.open(fileName, os.O_CREAT | os.O_EXCL | os.O_RDWR)
            os.close(fd)
            return fileName
        except OSError:
            pass
        fileName = file_name_parts[0] + '_' + str(counter) + file_name_parts[1]
        counter += 1
        
