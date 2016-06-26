# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-sailelfcloud

CONFIG += sailfishapp

SOURCES += src/SailElfCloud.cpp \
    src/Helpers.cpp

OTHER_FILES += \
    rpm/harbour-sailelfcloud.spec \
    rpm/harbour-sailelfcloud.yaml \

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-sailelfcloud-fi.ts

DISTFILES += \
    3rd/* \
    translations/*.ts \
    qml/python/* \
    qml/icons/* \
    qml/cover/CoverPage.qml \
    qml/ElfCloudAdapter.qml \
    qml/pages/LoginPage.qml \
    qml/pages/DataItemDetailsPage.qml \
    qml/pages/SubscriptionInfoPage.qml \
    qml/Settings.qml \
    qml/pages/ConnectionPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/ConfigPage.qml \
    qml/items/CommonPullDownMenu.qml \
    qml/dialogs/FileChooserDialog.qml \
    qml/items/ImageBackgroundItem.qml \
    qml/items/DocumentBackgroundItem.qml \
    qml/dialogs/AddVaultDialog.qml \
    qml/dialogs/AddClusterDialog.qml \
    rpm/harbour-sailelfcloud.changes \
    harbour-sailelfcloud.desktop \
    qml/dialogs/RenameDialog.qml \
    qml/views/FileSelectorView.qml \
    qml/views/ImageSelectorView.qml \
    qml/pages/DataItemContentPage.qml \
    qml/pages/ContainerPage.qml \
    qml/pages/AboutPage.qml \
    qml/dialogs/RemoveContainerDialog.qml \
    qml/pages/ProblemPage.qml \
    qml/harbour-sailelfcloud.qml \
    qml/items/ElfCloudAdapterCb.qml \
    qml/pages/EncryptionConfigPage.qml \
    qml/dialogs/ImportFromClipboardDialog.qml \
    qml/KeyHandler.qml \
    qml/dialogs/ImportFromFileDialog.qml \
    qml/dialogs/CreateNewKeyDialog.qml

unix: PKGCONFIG +=

pycrypto.target = pycrypto
pycrypto.commands = CFLAGS="" ; CXXFLAGS="" FFLAGS="" ; export && tar xzf $$PWD/3rd/pycrypto-2.6.1.tar.gz  && cd pycrypto-2.6.1 && patch -p0 -i $$PWD/3rd/pycrypto.patch && python3 setup.py bdist_egg
pycrypto_install.commands = cp pycrypto-2.6.1/dist/pycrypto-2.6.1-py3.4-linux-*.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
pycrypto_install.path = /usr/share/harbour-sailelfcloud/lib

pyaes.target = pyaes
pyaes.commands = tar xzf $$PWD/3rd/pyaes-1.6.0.tar.gz && cd pyaes-1.6.0 && patch -p0 -i $$PWD/3rd/pyaes.patch && python3 setup.py bdist_egg
pyaes_install.commands = cp pyaes-1.6.0/dist/pyaes-1.6.0-py3.4.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
pyaes_install.path = /usr/share/harbour-sailelfcloud/lib

decorator.target = decorator
decorator.commands = tar xzf $$PWD/3rd/decorator-4.0.9.tar.gz && cd decorator-4.0.9 && python3 setup.py bdist_egg
decorator_install.commands = cp decorator-4.0.9/dist/decorator-4.0.9-py3.4.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
decorator_install.path = /usr/share/harbour-sailelfcloud/lib

elfcloud.target = elfcloud
elfcloud.commands = rm -Rf elfcloud-weasel-1.2.2 && tar xzf $$PWD/3rd/elfcloud-weasel-1.2.2.tar.gz && patch -p1 -i $$PWD/3rd/elfcloud.patch && cd elfcloud-weasel-1.2.2 && python3 setup.py bdist_egg
elfcloud_install.commands = cp elfcloud-weasel-1.2.2/dist/elfcloud_weasel-1.2.2-py3.4.egg $(INSTALL_ROOT)/usr/share/harbour-sailelfcloud/lib
elfcloud_install.path = /usr/share/harbour-sailelfcloud/lib

QMAKE_EXTRA_TARGETS += pycrypto pyaes decorator elfcloud
POST_TARGETDEPS += pycrypto pyaes decorator elfcloud
INSTALLS += pycrypto_install pyaes_install decorator_install elfcloud_install

HEADERS += \
    src/Helpers.h
