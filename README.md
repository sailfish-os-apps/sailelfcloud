# sailelfcloud
ElfCloud port for Sailfish

elfCloud is a product of elfGROUP. See https://secure.elfcloud.fi/en_US/.

BUILD
=====

You should have Sailfish SDK installed. See
https://sailfishos.org/develop/sdk-overview/

Download following dependencies to 3rd/ directory:
 * elfcloud-weasel
    wget https://secure.elfcloud.fi/download/client/elfcloud-weasel-1.2.2.tar.gz
 * pycrypto
    wget https://pypi.python.org/packages/60/db/645aa9af249f059cc3a368b118de33889219e0362141e75d4eaf6f80f163/pycrypto-2.6.1.tar.gz#md5=55a61a054aa66812daf5161a0d5d7eda
 * decorator
    wget https://pypi.python.org/packages/68/04/621a0f896544814ce6c6a0e6bc01d19fc41d245d4515a2e4cf9e07a45a12/decorator-4.0.9.tar.gz#md5=f12c5651ccd707e12a0abaa4f76cd69a

To build and run follow instructions from:
https://sailfishos.org/develop/tutorials/building-sailfish-os-packages-manually/

or use Sailfish QT Creator to build&deploy the application.

NOTE! Initial build of pycrypto takes ages to complete sometimes. It
looks almost like the build process whould be stuck but after a minute
or two it continues.


TODO
====

Suggest elfGROUP to port elfcloud-weasel to support python3 and preferably
also dependency to decorator and pycryto should be get rid of.
