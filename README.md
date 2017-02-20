# sailelfcloud
elfCLOUD client for Sailfish

elfCLOUD is a product of elfGROUP. See https://secure.elfcloud.fi/en_US/.

BUILD
=====

Install dependencies
--------------------

You should have Sailfish SDK installed. See
https://sailfishos.org/develop/sdk-overview/

Install following dependencies to Sailfish SDK:
 * python3-devel

Dependency installation can be done in Mer build engine:
```
sb2 -t SailfishOS-i486 -m sdk-install -R zypper in python3-devel
sb2 -t SailfishOS-armv7hl -m sdk-install -R zypper in python3-devel
```

Build SW
--------

To build and run follow instructions from:
https://sailfishos.org/develop/tutorials/building-sailfish-os-packages-manually/

or use Sailfish QT Creator to build&deploy the application.

Project layout is based on https://github.com/amarchen/helloworld-pro-sailfish

RUN TESTS
=========

For python code:
 - Install python3, python3-unittest, python3-mock, python3-pytest
 - cd src/qml/python/tests
 - PYTHONPATH=../:../../../3rd/elfcloud-weasel/:../../../3rd/decorator/build/lib/ py.test-3


TODO
====

See https://github.com/TeemuAhola/sailelfcloud/wiki
