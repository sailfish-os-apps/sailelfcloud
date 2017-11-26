#ifndef HELPERS
#define HELPERS

#include <QObject>
#include <QStringList>
#include <QProcess>

class Helpers : public QObject {
   Q_OBJECT
public:
    explicit Helpers (QObject* parent = 0) : QObject(parent) {}

    void init(void);
    void uninit(void);

    Q_INVOKABLE QString getStandardWritableLocationDocuments(void) const;
    Q_INVOKABLE QString getStandardWritableLocationDownloads(void) const;

    Q_INVOKABLE QStringList getStandardLocationPictures(void) const;
    Q_INVOKABLE QStringList getStandardLocationDocuments(void) const;
    Q_INVOKABLE QStringList getStandardLocationDownloads(void) const;
    Q_INVOKABLE QStringList getStandardLocationVideo(void) const;
    Q_INVOKABLE QStringList getStandardLocationMusic(void) const;

    Q_INVOKABLE bool isFirstTimeDone(void) const;
    Q_INVOKABLE void setFirstTimeDone(void) const;
    Q_INVOKABLE void clearFirstTimeDone(void) const;

    Q_INVOKABLE bool isRememberLogin(void) const;
    Q_INVOKABLE void setRememberLogin(void) const;
    Q_INVOKABLE void clearRememberLogin(void) const;
    bool containsRememberLogin(void) const;

    Q_INVOKABLE QString getSettingsUserName(void) const;
    Q_INVOKABLE void setSettingsUserName(const QString name) const;

    Q_INVOKABLE QString getSettingsPassword(void) const;
    Q_INVOKABLE void setSettingsPassword(const QString pw) const;

    Q_INVOKABLE void setSettingsUserNamePassword(const QString name, const QString pw) const;
    Q_INVOKABLE void clearSettingsUserNamePassword(void) const;

    Q_INVOKABLE QString getSettingsKeyringPassword(void) const;
    Q_INVOKABLE void setSettingsKeyringPassword(const QString pw) const;

    Q_INVOKABLE bool isAutoLogin(void) const;
    Q_INVOKABLE void setAutoLogin(void) const;
    Q_INVOKABLE void clearAutoLogin(void) const;
    Q_INVOKABLE bool isAutoLoginAllowed(void) const;

    Q_INVOKABLE void setActiveKey(const QString keyHash) const;
    Q_INVOKABLE void clearActiveKey() const;
    Q_INVOKABLE QString getActiveKey() const;
    Q_INVOKABLE bool isActiveKey() const;

    Q_INVOKABLE void clearLoginInformation(void) const;

    Q_INVOKABLE QStringList getListOfFiles(const QString directory) const;
    Q_INVOKABLE QStringList getListOfDirs(const QString directory) const;
    Q_INVOKABLE QStringList getListOfFilesRecursively(const QString directory) const;

    Q_INVOKABLE QString getFilenameFromPath(const QString path) const;

    Q_INVOKABLE qint64 getFileSize(const QString path) const;
    Q_INVOKABLE QString getFileMimeType(const QString path) const;

    Q_INVOKABLE QString readPlainFile(const QString path) const;
    Q_INVOKABLE bool moveAndRenameFileAccordingToMime(const QString path, const QString destFilename, bool overwrite) const;

    Q_INVOKABLE QString generateLocalPathForRemoteDataItem(int parentId, const QString name) const;

    Q_INVOKABLE bool viewFileWithApplication(const QString path);

    Q_INVOKABLE QString hashDataBeaverMd5Hex(const QString dataInHexString);
    Q_INVOKABLE QString generateKey(const QString currentKeyInHexString, const int dataAdditionAsInt);

signals:
    void applicationExited(int exitCode);

private slots:
    void handleProcessFinish(int exitCode, QProcess::ExitStatus status);
    void handleProcessError(QProcess::ProcessError error);
    void handleAboutToQuit(void);

private:
    QProcess *m_process;

    QStringList getSdcardPaths(void) const;
    QStringList getValidLocations(const QStringList & dirnames, const QString & subdir) const;

    static QString getStandardWritableLocationPictures(void);
    static QString getStandardWritableLocationCamera(void);
    static QString getStandardWritableLocationVideo(void);
    static QString getStandardWritableLocationAudio(void);
    static QString getDataDir(void);
    static QString getDownloadCacheDir(void);
    static QString getConfigDir(void);
    static QString getOfflineStorageDir(void);
    static QString getSettingsDir(void);

    static void prepareCache(void);
    static void dropCache(void);
    static void initPython();
    void initConfig(void);
};

#endif // HELPERS

