TEMPLATE = app

# The name of your app
TARGET = tst-harbour-sailelfcloud

CONFIG += warn_on qmltestcase

TARGETPATH = /usr/bin
target.path = $$TARGETPATH

DEPLOYMENT_PATH = /usr/share/$$TARGET
qml.path = $$DEPLOYMENT_PATH

extra.path = $$DEPLOYMENT_PATH
extra.files = runTestsOnDevice.sh 3rd/js-mock/dist/*.js

# defining QUICK_TEST_SOURCE_DIR here doesn't work QtCreator keeps injecting another definition to command line (from CONFIG += qmltestcase ?)
#DEFINES += QUICK_TEST_SOURCE_DIR=\"\\\"\"$${DEPLOYMENT_PATH}/\"\\\"\"
DEFINES += DEPLOYMENT_PATH=\"\\\"\"$${DEPLOYMENT_PATH}/\"\\\"\"

# C++ sources
SOURCES += main.cpp

# C++ headers
HEADERS +=

INSTALLS += target qml extra

# QML files and folders
qml.files = *.qml

OTHER_FILES +=

DISTFILES += \
    ElfCloudAdapterMock.qml \
    HelpersMock.qml \
    tst_ConnectionPage.qml \
    tst_TransfersPage.qml \
    tst_ContainerPage.qml \
    tst_KeychainBackupPage.qml \
    tst_keyBackup.qml \
    3rd/js-mock/dist/*.js



