'''
Created on Sep 18, 2016

@author: teemu
'''

import elfcloud
import logger

try:
    import pyotherside
except ImportError:
    import sys
    # Allow testing Python backend alone.
    print("PyOtherSide not found, continuing anyway!")
    class pyotherside:
        def atexit(self, *args): pass
        def send(self, *args):
            print("send:", [str(a) for a in args])
    sys.modules["pyotherside"] = pyotherside()

def _sendExceptionSignal(id_, message):
    pyotherside.send('exception', id_, message)

def handle_exception(func):
    from functools import wraps
    @wraps(func)
    def exception_handler(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except elfcloud.exceptions.ECAuthException as e:
            logger.error("elfCLOUD exception occurred:", str(e))
            _sendExceptionSignal(e.id, e.message)            
        except elfcloud.exceptions.ECException as e:
            logger.error("elfCLOUD exception occurred:", str(e))
            _sendExceptionSignal(e.id, e.message)
        except elfcloud.exceptions.ClientException as e:
            logger.error("Client exception occurred:", str(e))
            _sendExceptionSignal(0, e.message)
        except Exception as e:
            logger.error("Undefined exception occurred:", str(e))
            _sendExceptionSignal(0, str(e))
            
    return exception_handler

