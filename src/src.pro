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
           Helpers.cpp \
           Logger.cpp

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
    qml/cover/* \
    qml/dialogs/* \
    qml/items/* \
    qml/pyton/* \
    qml/pages/TransfersPage.qml \
    qml/items/Notifications.qml \
    qml/pages/CurrentUserPage.qml \
    qml/helpers/keyBackup.js

OTHER_FILES = \
    ../rpm/harbour-sailelfcloud.yaml \
    ../rpm/harbour-sailelfcloud.spec \
    ../rpm/harbour-sailelfcloud.changes

INCLUDEPATH += $$PWD

pycrypto.target = pycrypto
pycrypto.commands = CFLAGS="" ; CXXFLAGS="" FFLAGS="" ; cd $$PWD/3rd/pycrypto && python3 setup.py bdist_egg --bdist-dir $$OUT_PWD/build/pycrypto --dist-dir $$OUT_PWD/dist
pycrypto.extra = cp $$OUT_PWD/dist/pycrypto*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib/
pycrypto.path = $$DEPLOYMENT_PATH/lib

decorator.target = decorator
decorator.commands = cd $$PWD/3rd/decorator && python3 setup.py bdist_egg --bdist-dir $$OUT_PWD/build/decorator --dist-dir $$OUT_PWD/dist
decorator.extra = cp $$OUT_PWD/dist/decorator*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
decorator.path = $$DEPLOYMENT_PATH/lib

elfcloud.target = elfcloud
elfcloud.commands = cd $$PWD/3rd/elfcloud-weasel && python3 setup.py bdist_egg --bdist-dir $$OUT_PWD/build/elfcloud-weasel --dist-dir $$OUT_PWD/dist
elfcloud.extra = cp $$OUT_PWD/dist/elfcloud_weasel*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
elfcloud.path = $$DEPLOYMENT_PATH/lib

QMAKE_EXTRA_TARGETS += pycrypto decorator elfcloud
PRE_TARGETDEPS += pycrypto decorator elfcloud
INSTALLS += pycrypto decorator elfcloud
