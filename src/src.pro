# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
# Must start with "harbour-"
TARGET = harbour-sailelfcloud

# In the bright future this config line will do a lot of stuff to you
CONFIG += sailfishapp

SOURCES += SailElfCloud.cpp \
           Helpers.cpp

HEADERS += Helpers.h

DEPLOYMENT_PATH = /usr/share/$$TARGET

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256
CONFIG += sailfishapp_i18n
TRANSLATIONS += translations/harbour-sailelfcloud-fi.ts

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_BUILDNUM=\\\"$$RELEASE\\\"

DISTFILES += \
    3rd/*.egg \
    translations/*.ts \
    harbour-sailelfcloud.desktop \
    qml/* \
    qml/pages/* \
    qml/views/* \
    qml/covers/* \
    qml/dialogs/* \
    qml/items/* \
    qml/pyton/*

OTHER_FILES = \
    ../rpm/harbour-sailelfcloud.yaml \
    ../rpm/harbour-sailelfcloud.spec \
    ../rpm/harbour-sailelfcloud.changes \

INCLUDEPATH += $$PWD

pycrypto.target = pycrypto
pycrypto.commands = CFLAGS="" ; CXXFLAGS="" FFLAGS="" ; tar xzf $$PWD/3rd/pycrypto-2.6.1.tar.gz  && cd pycrypto-2.6.1 && patch -p0 -i $$PWD/3rd/pycrypto.patch && python3 setup.py bdist_egg
pycrypto_install.commands = cp pycrypto-2.6.1/dist/pycrypto-2.6.1-*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib/
pycrypto_install.path = $$DEPLOYMENT_PATH/lib

decorator.target = decorator
decorator.commands = tar xzf $$PWD/3rd/decorator-4.0.9.tar.gz && cd decorator-4.0.9 && python3 setup.py bdist_egg
decorator_install.commands = cp decorator-4.0.9/dist/decorator-4.0.9-*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
decorator_install.path = $$DEPLOYMENT_PATH/lib

elfcloud.target = elfcloud
elfcloud.commands = rm -Rf elfcloud-weasel-1.2.2 && tar xzf $$PWD/3rd/elfcloud-weasel-1.2.2.tar.gz && patch -p1 -i $$PWD/3rd/elfcloud.patch && cd elfcloud-weasel-1.2.2 && python3 setup.py bdist_egg
elfcloud_install.commands = cp elfcloud-weasel-1.2.2/dist/elfcloud_weasel-1.2.2-*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
elfcloud_install.path = $$DEPLOYMENT_PATH/lib

QMAKE_EXTRA_TARGETS += pycrypto decorator elfcloud
POST_TARGETDEPS += pycrypto decorator elfcloud
INSTALLS += pycrypto_install decorator_install elfcloud_install
