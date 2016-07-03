TEMPLATE=app
# The name of your app binary (and it's better if you think it is the whole app name as it's referred to many times)
# Must start with "harbour-"
TARGET = harbour-sailelfcloud

# In the bright future this config line will do a lot of stuff to you
CONFIG += sailfishapp

SOURCES += SailElfCloud.cpp \
           Helpers.cpp

HEADERS += Helpers.h

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256
CONFIG += sailfishapp_i18n
TRANSLATIONS += translations/harbour-sailelfcloud-fi.ts

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_BUILDNUM=\\\"$$RELEASE\\\"

DISTFILES += \
    3rd/*.egg \
    translations/*.ts \
    harbour-sailelfcloud.desktop \
    qml/*

OTHER_FILES = \
# You DO NOT want .yaml be listed here as Qt Creator's editor is completely not ready for multi package .yaml's
#
# Also Qt Creator as of Nov 2013 will anyway try to rewrite your .yaml whenever you change your .pro
# Well, you will just have to restore .yaml from version control again and again unless you figure out
# how to kill this particular Creator's plugin
#    ../rpm/harbour-sailelfcloud.yaml \
    ../rpm/harbour-sailelfcloud.spec \
    ../rpm/harbour-sailelfcloud.changes

INCLUDEPATH += $$PWD

pycrypto.target = pycrypto
pycrypto.commands = CFLAGS="" ; CXXFLAGS="" FFLAGS="" ; tar xzf $$PWD/3rd/pycrypto-2.6.1.tar.gz  && cd pycrypto-2.6.1 && patch -p0 -i $$PWD/3rd/pycrypto.patch && python3 setup.py bdist_egg
pycrypto_install.commands = cp pycrypto-2.6.1/dist/pycrypto-2.6.1-*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib/
pycrypto_install.path = /usr/share/harbour-sailelfcloud/lib

decorator.target = decorator
decorator.commands = tar xzf $$PWD/3rd/decorator-4.0.9.tar.gz && cd decorator-4.0.9 && python3 setup.py bdist_egg
decorator_install.commands = cp decorator-4.0.9/dist/decorator-4.0.9-*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
decorator_install.path = /usr/share/harbour-sailelfcloud/lib

elfcloud.target = elfcloud
elfcloud.commands = rm -Rf elfcloud-weasel-1.2.2 && tar xzf $$PWD/3rd/elfcloud-weasel-1.2.2.tar.gz && patch -p1 -i $$PWD/3rd/elfcloud.patch && cd elfcloud-weasel-1.2.2 && python3 setup.py bdist_egg
elfcloud_install.commands = cp elfcloud-weasel-1.2.2/dist/elfcloud_weasel-1.2.2-*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
elfcloud_install.path = /usr/share/harbour-sailelfcloud/lib

QMAKE_EXTRA_TARGETS += pycrypto decorator elfcloud
POST_TARGETDEPS += pycrypto decorator elfcloud
INSTALLS += pycrypto_install decorator_install elfcloud_install
