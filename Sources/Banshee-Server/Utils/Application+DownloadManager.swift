import Vapor

extension Application {
    struct DownloadManagerKey: StorageKey {
        typealias Value = DownloadManager
    }

    var downloadManager: DownloadManager {
        get {
            let manager = storage[DownloadManagerKey.self]
            precondition(manager != nil, "DownloadManager not added to application before being used.")
            return manager!
        }
        set { storage[DownloadManagerKey.self] = newValue }
    }
}

extension Request {
    var downloadManager: DownloadManager {
        application.downloadManager
    }
}