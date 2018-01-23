# sailelfcloud


NOTE! Sadly elfCLOUD service is going to be shutdown at 15th of June 2018. It means that this application will become deprecated as well and not maintained. For more details about elfCLOUD see https://secure.elfcloud.fi/en_US/.


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

E.g. login first to Mer build engine and then for i486:
```
mkdir build-i486 && cd build-i486
mb2 -t SailfishOS-i486 -p your_source_dir/ qmake your_source_dir/SailElfCloud.pro
mb2 -t SailfishOS-i486 -p your_source_dir/ rpm
```

and for ARM:
```
mkdir build-armv7hl && cd build-armv7hl
mb2 -t SailfishOS-armv7hl -p your_source_dir/ qmake your_source_dir/SailElfCloud.pro
mb2 -t SailfishOS-armv7hl -p your_source_dir/ rpm
```

RUN TESTS
=========

For python code:
 - Install python3, python3-unittest, python3-mock, python3-pytest
 - cd src/qml/python/tests
 - PYTHONPATH=../:../../../3rd/elfcloud-weasel/:../../../3rd/decorator/build/lib/ py.test-3


TODO
====

See https://github.com/TeemuAhola/sailelfcloud/wiki
