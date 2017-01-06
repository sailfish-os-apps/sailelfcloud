# sailelfcloud
elfCLOUD client for Sailfish

elfCLOUD is a product of elfGROUP. See https://secure.elfcloud.fi/en_US/.

BUILD
=====

Install dependencies
--------------------

You should have Sailfish SDK installed. See
https://sailfishos.org/develop/sdk-overview/

Download following dependencies to 3rd/ directory:
 * elfcloud-weasel
    https://pypi.python.org/packages/0e/d9/c7627f465959d3058285d43f47de45ba547fe754700c4cc9ca3d890a2f21/elfcloud-weasel-1.2.2.tar.gz#md5=6b37eedf3a57697db0c17578c81f6ea4
 * pycrypto
    https://pypi.python.org/packages/60/db/645aa9af249f059cc3a368b118de33889219e0362141e75d4eaf6f80f163/pycrypto-2.6.1.tar.gz#md5=55a61a054aa66812daf5161a0d5d7eda
 * decorator
    https://pypi.python.org/packages/68/04/621a0f896544814ce6c6a0e6bc01d19fc41d245d4515a2e4cf9e07a45a12/decorator-4.0.9.tar.gz#md5=f12c5651ccd707e12a0abaa4f76cd69a

Install following dependencies to Sailfish SDK:
 * python3-devel

E.g. on Mer build engine:
```
sb2 -t SailfishOS-i486 -m sdk-install -R zypper in python3-devel' and
sb2 -t SailfishOS-armv7hl -m sdk-install -R zypper in python3-devel' in MerSDK.
```

Build SW
--------

To build and run follow instructions from:
https://sailfishos.org/develop/tutorials/building-sailfish-os-packages-manually/

or use Sailfish QT Creator to build&deploy the application.

Project layout is based on https://github.com/amarchen/helloworld-pro-sailfish

RUN TESTS
=========

TBD

TODO
====

See https://github.com/TeemuAhola/sailelfcloud/wiki
