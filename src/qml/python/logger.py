'''
Created on Sep 17, 2016

@author: teemu
'''

try:
    import pyotherside
except ImportError:
    import sys
    # Allow testing Python backend alone.
    print("PyOtherSide not found, continuing anyway!")
    class pyotherside:
        def atexit(self, *args): pass
        def send(self, *args):
            print("printout:", [str(a) for a in args])
    sys.modules["pyotherside"] = pyotherside()

def debug(*text):
    pyotherside.send('log-d', ' '.join([str(s) for s in text]))

def info(*text):
    pyotherside.send('log-i', ' '.join([str(s) for s in text]))

def error(*text):
    pyotherside.send('log-e', ' '.join([str(s) for s in text]))
