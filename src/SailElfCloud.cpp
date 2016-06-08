#include <QtQuick>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <sailfishapp.h>
#include "Helpers.h"


int main(int argc, char *argv[])
{
    // Set up qml engine.
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> v(SailfishApp::createView());

    // If you wish to publish your app on the Jolla harbour, it is recommended
    // that you prefix your internal namespaces with "harbour.".
    //
    // For details see:
    // https://harbour.jolla.com/faq#1.5.0

    qmlRegisterType<Helpers>("harbour.sailelfcloud.helpers", 1, 0, "Helpers");
    Helpers helpers;
    helpers.prepareCache();

    // Start the application.
    v->setSource(SailfishApp::pathTo("qml/SailElfCloud.qml"));
    v->show();
    return app->exec();
}

