#ifndef HELPERS
#define HELPERS

#include <QObject>
#include <QStringList>

class Helpers : public QObject {
   Q_OBJECT
public:
    explicit Helpers (QObject* parent = 0) : QObject(parent) {}

    Q_INVOKABLE QString getDataDir(void) const;
    Q_INVOKABLE QString getCacheDir(void) const;
    Q_INVOKABLE QString getConfigDir(void) const;
    Q_INVOKABLE QString getOfflineStorageDir(void) const;
    Q_INVOKABLE QString getSettingsDir(void) const;

    Q_INVOKABLE bool isRememberLogin(void) const;
    Q_INVOKABLE void setRememberLogin(void) const;
    Q_INVOKABLE void clearRememberLogin(void) const;

    Q_INVOKABLE QString getSettingsUserName(void) const;
    Q_INVOKABLE void setSettingsUserName(const QString name) const;

    Q_INVOKABLE QString getSettingsPassword(void) const;
    Q_INVOKABLE void setSettingsPassword(const QString pw) const;

    Q_INVOKABLE void setSettingsUserNamePassword(const QString name, const QString pw) const;
    Q_INVOKABLE void clearSettingsUserNamePassword(void) const;

    Q_INVOKABLE bool isAutoLogin(void) const;
    Q_INVOKABLE void setAutoLogin(void) const;
    Q_INVOKABLE void clearAutoLogin(void) const;
    Q_INVOKABLE bool isAutoLoginAllowed(void) const;

    Q_INVOKABLE void clearLoginInformation(void) const;

    Q_INVOKABLE QStringList getListOfFiles(const QString directory) const;
    Q_INVOKABLE QStringList getListOfDirs(const QString directory) const;
    Q_INVOKABLE QStringList getListOfFilesRecursively(const QString directory) const;

    Q_INVOKABLE QString getFilenameFromPath(const QString path) const;

    Q_INVOKABLE qint64 getFileSize(const QString path) const;
    Q_INVOKABLE QString getFileMimeType(const QString path) const;

    Q_INVOKABLE QString readPlainFile(const QString path) const;
    Q_INVOKABLE bool moveAndRenameFileAccordingToMime(const QString path, const QString destFilename) const;

private:
    QString getStandardLocationPictures(void) const;
    QString getStandardLocationCamera(void) const;
    QString getStandardLocationDocuments(void) const;
    QString getStandardLocationDownloads(void) const;
    QString getStandardLocationVideo(void) const;
    QString getStandardLocationAudio(void) const;

};

#endif // HELPERS

