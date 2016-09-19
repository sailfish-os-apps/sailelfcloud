'''
Created on Sep 18, 2016

@author: teemu
'''

import elfcloud

class ClientException(Exception):
    
    def __init__(self, id_=0, msg_="unknown"):
        self.__id = id_
        self.__msg = msg_
        
    @property
    def id(self):
        return self.__id

    @property
    def msg(self):
        return self.__msg

class NotConnected(elfcloud.exceptions.ClientException):
    
    def __init__(self):
        elfcloud.exceptions.ClientException.__init__(self, "not connected")

def handle_exception(func):
    from functools import wraps
    @wraps(func)
    def exception_handler(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except elfcloud.exceptions.ECAuthException as e:
            raise ClientException(e.id, e.message) from e
        except elfcloud.exceptions.ECException as e:
            raise ClientException(e.id, e.message) from e            
        except elfcloud.exceptions.ClientException as e:
            raise ClientException(e.id, e.message) from e
        except NotConnected as e:
            raise ClientException(e.id, e.message) from e
        except Exception as e:
            raise ClientException(e.id, e.message) from e
            
    return exception_handler

