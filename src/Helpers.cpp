#include <QtDebug>
#include <QQmlEngine>
#include <QSettings>
#include <QCoreApplication>
#include <QStandardPaths>
#include <QDir>
#include <QMimeDatabase>
#include <QMimeType>
#include <QTextStream>
#include <QCryptographicHash>
#include <QDebug>

#include "Helpers.h"

bool Helpers::containsRememberLogin(void) const
{
    QSettings s;
    return s.contains("user/remember");
}

bool Helpers::isRememberLogin(void) const
{
    QSettings s;
    return s.value("user/remember", false).toBool();
}

void Helpers::setRememberLogin(void) const
{
    QSettings s;
    s.setValue("user/remember", true);
}

void Helpers::clearRememberLogin(void) const
{
    QSettings s;
    s.setValue("user/remember", false);
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

void Helpers::setSettingsUserNamePassword(const QString name, const QString pw) const
{
    setSettingsUserName(name);
    setSettingsPassword(pw);
}

void Helpers::setActiveKey(const QString keyHash) const
{
    QSettings s;
    return s.setValue("user/activekey", keyHash);
}

void Helpers::clearActiveKey() const
{
    QSettings s;
    s.remove("user/activekey");
}

QString Helpers::getActiveKey() const
{
    QSettings s;
    return s.value("user/activekey").toString();
}

bool Helpers::isActiveKey() const
{
    QSettings s;
    return s.contains("user/activekey");
}

void Helpers::clearSettingsUserNamePassword(void) const
{
    QSettings s;
    s.remove("user/name");
    s.remove("user/passw");
    clearActiveKey();
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
    s.remove("user/remember");
    s.remove("config/autologin");
    clearSettingsUserNamePassword();
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

QString Helpers::readPlainFile(const QString path) const
{
    QFile f(path);
    QString returnString;

    if (f.open(QFile::ReadOnly | QIODevice::Text)) {
        QTextStream in(&f);
        returnString = in.readAll();
        f.close();
    }

    return returnString;
}

QString Helpers::generateLocalPathForRemoteDataItem(int parentId, const QString name) const
{
    const QString path = getCacheDir() + QString("/") + QString::number(parentId);
    QDir d;
    d.mkpath(path);
    return path + QString("/") + name;
}

QString Helpers::getStandardLocationPictures(void)
{
    return QStandardPaths::standardLocations(QStandardPaths::PicturesLocation)[0];
}

QString Helpers::getStandardLocationCamera(void)
{
    return QStandardPaths::standardLocations(QStandardPaths::PicturesLocation)[0] + "/Camera";
}

QString Helpers::getStandardLocationDocuments(void) const
{
    return QStandardPaths::standardLocations(QStandardPaths::DocumentsLocation)[0];
}

QString Helpers::getStandardLocationDownloads(void) const
{
    return QStandardPaths::standardLocations(QStandardPaths::DownloadLocation)[0];
}

QString Helpers::getStandardLocationAudio(void)
{
    return QStandardPaths::standardLocations(QStandardPaths::MusicLocation)[0];
}

QString Helpers::getStandardLocationVideo(void)
{
    return QStandardPaths::standardLocations(QStandardPaths::MoviesLocation)[0];
}

bool Helpers::moveAndRenameFileAccordingToMime(const QString path, const QString destFilename, bool overwrite) const
{
    const QString mime = getFileMimeType(path);
    QString standardLocation;

    if (mime.contains("text/plain"))
        standardLocation = getStandardLocationDocuments();
    else if (mime.contains("image/"))
        standardLocation = getStandardLocationPictures();
    else if (mime.contains("audio/"))
        standardLocation = getStandardLocationAudio();
    else if (mime.contains("video/"))
        standardLocation = getStandardLocationVideo();
    else
        standardLocation = getStandardLocationDownloads();

    QString destination = standardLocation + "/"+ destFilename;

    if (QFile::exists(destination) && !overwrite) {
        qDebug() << "Destination file" << destination << "exists";
        return false;
    }
    else if (overwrite)
        QFile::remove(destination);

    qDebug() << "Moving file of mime type" << mime << "to" << destination;
    return QFile::rename(path, destination);
}

QString Helpers::getDataDir(void)
{
    return QStandardPaths::writableLocation(QStandardPaths::DataLocation);
}

QString Helpers::getCacheDir(void)
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
}

QString Helpers::getConfigDir(void)
{
    return QDir(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)).
            filePath(QCoreApplication::applicationName());
}

QString Helpers::getOfflineStorageDir(void)
{
    QQmlEngine engine;
    return engine.offlineStoragePath();
}

QString Helpers::getSettingsDir(void)
{
    QSettings s;
    return s.fileName();
}

void Helpers::handleProcessFinish(int exitCode, QProcess::ExitStatus status)
{
    Q_UNUSED(status);
    emit applicationExited(exitCode);
}

void Helpers::handleProcessError(QProcess::ProcessError error)
{
    Q_UNUSED(error);
    emit applicationExited(-88888);
 }

bool Helpers::viewFileWithApplication(const QString path)
{
    qDebug() << "Opening " << path << " with external application";
    const QString COMMAND = "xdg-open";
    m_process = new QProcess(this);
    connect(m_process, SIGNAL(finished(int, QProcess::ExitStatus)), this, SLOT(handleProcessFinish(int, QProcess::ExitStatus)));
    connect(m_process, SIGNAL(error(QProcess::ProcessError)), this, SLOT(handleProcessError(QProcess::ProcessError)));
    m_process->start(COMMAND, QStringList(path));
    return true;
}

// elfCloud Beaver compatible MD5 hasher for initialization vector and key
// see KHA definition in https://secure.elfcloud.fi/en/developers/api-doc/?json#http-headers
QString Helpers::hashDataBeaverMd5Hex(const QString dataInHexString)
{
    QByteArray result = QByteArray::fromHex(dataInHexString.toLocal8Bit());

    for (int i = 0; i < 10000; i++)
    {
        result = QCryptographicHash::hash(result, QCryptographicHash::Md5);
    }

    return result.toHex();
}

QString Helpers::generateKey(const QString currentKeyInHexString, const int dataAdditionAsInt)
{
    const QByteArray data = QByteArray::number(dataAdditionAsInt);
    QByteArray currentKey = QByteArray::fromHex(currentKeyInHexString.toLocal8Bit()).append(data);
    QByteArray result = QCryptographicHash::hash(currentKey, QCryptographicHash::Sha512);
    return result.toHex();
}

void Helpers::prepareCache(void)
{
    QDir dir;
    dir.mkpath(getCacheDir());
}

void Helpers::initConfig(void)
{
    if (!containsRememberLogin())
        setRememberLogin();
}

void Helpers::init(void)
{
    initConfig();
    prepareCache();
}

void Helpers::dropCache(void)
{
    QDir dir(getCacheDir());
    dir.removeRecursively();
}

void Helpers::uninit(void)
{
    dropCache();
}

void Helpers::handleAboutToQuit(void)
{
    qDebug() << "Quitting...";
    uninit();
}
