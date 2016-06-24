# sailelfcloud
ElfCloud port for Sailfish

elfCloud is a product of elfGROUP. See https://secure.elfcloud.fi/en_US/.

BUILD
=====

You should have Sailfish SDK installed. See
https://sailfishos.org/develop/sdk-overview/

Download following dependencies to 3rd/ directory:
 * elfcloud-weasel
    https://secure.elfcloud.fi/download/client/elfcloud-weasel-1.2.2.tar.gz
 * pyaes
    https://pypi.python.org/packages/63/31/6768a72cdca5dbd299ae798b690801e6c9c2f018332eec3c5fca79370dba/pyaes-1.6.0.tar.gz#md5=516d3869e62e661031635270348193fe
 * decorator
    https://pypi.python.org/packages/68/04/621a0f896544814ce6c6a0e6bc01d19fc41d245d4515a2e4cf9e07a45a12/decorator-4.0.9.tar.gz#md5=f12c5651ccd707e12a0abaa4f76cd69a

Install following dependencies:
 * python3-devel

E.g. 'sb2 -t SailfishOS-i486 -m sdk-install -R zypper in python3-devel' and
'sb2 -t SailfishOS-armv7hl -m sdk-install -R zypper in python3-devel' in MerSDK.

To build and run follow instructions from:
https://sailfishos.org/develop/tutorials/building-sailfish-os-packages-manually/

or use Sailfish QT Creator to build&deploy the application.


TODO
====

Suggest elfGROUP to port elfcloud-weasel to support python3 and preferably
also dependency to decorator and pycryto should be get rid of.
