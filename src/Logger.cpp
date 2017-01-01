#include <QtGlobal>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QDebug>
#include <stdio.h>

static QFile logFile;

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

    QTextStream outStream(&logFile);
    outStream << output << "\n";

    if (type == QtFatalMsg)
        abort();
}


void initLogger(void)
{
    const QString logPath = QStandardPaths::standardLocations(QStandardPaths::CacheLocation)[0] + "/logs";
    qDebug() << "log path"<< logPath;
    QDir().mkpath(logPath);
    QFile::setPermissions(logPath, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);
    logFile.setFileName(logPath + "/log.txt");
    logFile.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text);

    qInstallMessageHandler(myMessageOutput);
}
