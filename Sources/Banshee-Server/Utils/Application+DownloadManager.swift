import Vapor

extension Application {
    struct DownloadManagerKey: StorageKey {
        typealias Value = DownloadManager
    }

    var downloadManager: DownloadManager {
        get { storage[DownloadManagerKey.self, default: DownloadManager()] }
        set { storage[DownloadManagerKey.self] = newValue }
    }
}

extension Request {
    var downloadManager: DownloadManager {
        application.downloadManager
    }
}