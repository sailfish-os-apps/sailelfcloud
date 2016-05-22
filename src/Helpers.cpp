#include <QQmlEngine>
#include <QSettings>
#include <QCoreApplication>
#include <QStandardPaths>
#include <QDir>
#include <QMimeDatabase>
#include <QMimeType>

#include "Helpers.h"

QString Helpers::getDataDir(void) const
{
    return QStandardPaths::writableLocation(QStandardPaths::DataLocation);
}

QString Helpers::getCacheDir(void) const
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
}

QString Helpers::getConfigDir(void) const
{
    return QDir(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)).
            filePath(QCoreApplication::applicationName());
}

QString Helpers::getOfflineStorageDir(void) const
{
    QQmlEngine engine;
    return engine.offlineStoragePath();
}

QString Helpers::getSettingsDir(void) const
{
    QSettings s;
    return s.fileName();
}

QString Helpers::getSettingsUserName(void) const
{
    QSettings s;
    return s.value("user/name").toString();
}

void Helpers::setSettingsUserName(const QString name) const
{
    QSettings s;
    s.setValue("user/name", name);
}

QString Helpers::getSettingsPassword(void) const
{
    QSettings s;
    return s.value("user/passw").toString();
}

void Helpers::setSettingsPassword(const QString pw) const
{
    QSettings s;
    s.setValue("user/passw", pw);
}

bool Helpers::isAutoLogin(void) const
{
    QSettings s;
    return s.value("config/autologin", false).toBool();
}

void Helpers::setAutoLogin(void) const
{
    QSettings s;
    s.setValue("config/autologin", true);
}

void Helpers::clearAutoLogin(void) const
{
    QSettings s;
    s.setValue("config/autologin", false);
}

bool Helpers::isAutoLoginAllowed(void) const
{
    QSettings s;

    if (isAutoLogin() &&
            s.contains("user/name") &&
            s.contains("user/passw")) {
        return true;
    }

    return false;
}

void Helpers::clearLoginInformation(void) const
{
    QSettings s;

    s.remove("user/name");
    s.remove("user/passw");
    s.remove("config/autologin");
}

QString Helpers::getStandardLocationPictures(void) const
{
    return QStandardPaths::standardLocations(QStandardPaths::PicturesLocation)[0];
}

QString Helpers::getStandardLocationCamera(void) const
{
    return QStandardPaths::standardLocations(QStandardPaths::PicturesLocation)[0] + "/Camera";
}

QStringList Helpers::getListOfFiles(const QString directory) const
{
    QDir recoredDir(directory);
    const QStringList allFileNames = recoredDir.entryList(QDir::NoDotAndDotDot | QDir::Files);
    QStringListIterator iter(allFileNames);
    QStringList allFiles;

    while (iter.hasNext())
        allFiles.append(directory + "/" + iter.next());

    return allFiles;
}

QStringList Helpers::getListOfDirs(const QString directory) const
{
    QDir recoredDir(directory);
    const QStringList allDirNames = recoredDir.entryList(QDir::NoDotAndDotDot | QDir::Dirs);
    QStringListIterator iter(allDirNames);
    QStringList allDirs;

    while (iter.hasNext())
        allDirs.append(directory + "/" + iter.next() + "/");

    return allDirs;
}

QStringList Helpers::getListOfFilesRecursively(const QString directory) const
{
    const QStringList dirs = getListOfDirs(directory) << directory;
    QStringListIterator iter(dirs);
    QStringList allFiles;

    while (iter.hasNext())
        allFiles += getListOfFiles(iter.next());

    return allFiles;
}

QString Helpers::getFilenameFromPath(const QString path) const
{
    QFileInfo f(path);
    return f.baseName()+"."+f.completeSuffix();
}

qint64 Helpers::getFileSize(const QString path) const
{
    return QFileInfo(path).size();
}

QString Helpers::getFileMimeType(const QString path) const
{
    return QMimeDatabase().mimeTypeForFile(path).name();
}

