#!/bin/bash

# Script for running tests. That's for specifying just one argument in QtCreator's configuration
/usr/bin/tst-harbour-sailelfcloud -o result.xml,xml -input /usr/share/tst-harbour-sailelfcloud -import /usr/share/harbour-sailelfcloud/qml/pages/

# When you'll get some QML components in the main app, you'll need to import them to the test run
# /usr/bin/tst-harbour-helloworld-pro-sailfish -o result.xml,xunitxml -input /usr/share/tst-harbour-helloworld-pro-sailfish -import /usr/share/harbour-helloworld-pro-sailfish/qml/components
