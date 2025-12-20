import Vapor

extension Application {
    struct DownloadManagerKey: StorageKey {
        typealias Value = DownloadManager
    }

    var downloadManager: DownloadManager {
        get {
            if let existing = storage[DownloadManagerKey.self] {
                return existing
            }

            // Initialize with proper storage path
            let storagePath = directory.workingDirectory + "Storage/episodes"
            let manager = DownloadManager(storageBasePath: storagePath)
            storage[DownloadManagerKey.self] = manager
            return manager
        }
        set { storage[DownloadManagerKey.self] = newValue }
    }
}

extension Request {
    var downloadManager: DownloadManager {
        application.downloadManager
    }
}