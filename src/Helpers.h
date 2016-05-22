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

    Q_INVOKABLE QString getSettingsUserName(void) const;
    Q_INVOKABLE void setSettingsUserName(const QString name) const;

    Q_INVOKABLE QString getSettingsPassword(void) const;
    Q_INVOKABLE void setSettingsPassword(const QString pw) const;

    Q_INVOKABLE bool isAutoLogin(void) const;
    Q_INVOKABLE void setAutoLogin(void) const;
    Q_INVOKABLE void clearAutoLogin(void) const;
    Q_INVOKABLE bool isAutoLoginAllowed(void) const;

    Q_INVOKABLE void clearLoginInformation(void) const;

    Q_INVOKABLE QString getStandardLocationPictures(void) const;
    Q_INVOKABLE QString getStandardLocationCamera(void) const;

    Q_INVOKABLE QStringList getListOfFiles(const QString directory) const;
    Q_INVOKABLE QStringList getListOfDirs(const QString directory) const;
    Q_INVOKABLE QStringList getListOfFilesRecursively(const QString directory) const;

    Q_INVOKABLE QString getFilenameFromPath(const QString path) const;

    Q_INVOKABLE qint64 getFileSize(const QString path) const;
    Q_INVOKABLE QString getFileMimeType(const QString path) const;
};

#endif // HELPERS

