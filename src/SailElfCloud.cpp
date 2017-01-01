#include <QtGlobal>
#include <QtQuick>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <sailfishapp.h>
#include "Helpers.h"

static void myMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QDateTime local(QDateTime::currentDateTime());
    QDateTime UTC(local.toTimeSpec(Qt::UTC));
    QString output;

    switch (type) {
    case QtDebugMsg:
        output =+ "[D]";
        break;
    case QtWarningMsg:
        output += "[W]";
        break;
    case QtCriticalMsg:
        output += "[C]";
        break;
    case QtFatalMsg:
        output += "[F]";
        break;
    default:
        output += "[?]";
    }

    output += " " + msg + " (" + context.file + ":" + QString::number(context.line) + ", " + context.function + ") [" + UTC.toString("yyyy.MM.dd|hh:mm:ss") + "]";

#ifdef QT_DEBUG
    fprintf(stderr, "%s\n", output.toLocal8Bit().data());
#endif

    const QString logPath = QStandardPaths::standardLocations(QStandardPaths::CacheLocation)[0] + "/logs";
    QDir dir;
    dir.mkpath(logPath);
    QFile::setPermissions(logPath, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);
    QFile logFile(logPath + "/log.txt");
    logFile.open(QIODevice::ReadWrite | QIODevice::Append | QIODevice::Text);
    QTextStream out(&logFile);
    out << output << "\n";

    if (type == QtFatalMsg)
        abort();
}

int main(int argc, char *argv[])
{
    qInstallMessageHandler(myMessageOutput);

    // Set up qml engine.
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> v(SailfishApp::createView());

    // If you wish to publish your app on the Jolla harbour, it is recommended
    // that you prefix your internal namespaces with "harbour.".
    //
    // For details see:
    // https://harbour.jolla.com/faq#1.5.0

    QScopedPointer<Helpers> helpers(new Helpers);
    v->rootContext()->setContextProperty("helpers", helpers.data());
    QObject::connect(app.data(), SIGNAL(aboutToQuit()),
                     helpers.data(), SLOT(handleAboutToQuit()));
    helpers->init();

    v->rootContext()->setContextProperty("appVersion", APP_VERSION);
    v->rootContext()->setContextProperty("appBuildNum", APP_BUILDNUM);

    // Start the application.
    v->setSource(SailfishApp::pathTo("qml/harbour-sailelfcloud.qml"));
    v->show();
    return app->exec();
}

