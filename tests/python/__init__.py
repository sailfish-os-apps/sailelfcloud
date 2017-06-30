import sys, os

curdir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(os.path.abspath(curdir + '/../../src/qml/python/'))
sys.path.append(os.path.abspath(curdir + '/../../src/3rd/elfcloud-weasel'))

ut_username = os.environ.get('UT_USERNAME')
ut_password = os.environ.get('UT_PASSWORD')
