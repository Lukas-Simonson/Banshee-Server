import NIOCore
import Vapor

extension Application {
    struct DownloadManagerKey: StorageKey {
        typealias Value = DownloadManager
    }
    
    var downloadManager: DownloadManager {
        get {
            let manager = storage[DownloadManagerKey.self]
            precondition(manager != nil, "DownloadManager not added to application before use.")
            return manager!
        }
        set {
            storage[DownloadManagerKey.self] = newValue
        }
    }
}

final actor DownloadManager {
    private let client: HTTPClient
    private let data: any DownloadData
    private let files: FileManager
    
    nonisolated let downloadPath: String
    private let downloadTimeoutSeconds: Int64
    private let maxConcurrentDownloads: Int
    private var current = [EpisodeDownload]()
    
    init(at path: String, client: HTTPClient, data: any DownloadData, files: FileManager, downloadTimeoutSeconds: Int64 = 3600, maxConcurrentDownloads: Int = 3) {
        self.downloadPath = path
        self.client = client
        self.data = data
        self.files = files
        self.downloadTimeoutSeconds = downloadTimeoutSeconds
        self.maxConcurrentDownloads = maxConcurrentDownloads
    }
    
    /// Starts a new download operation if the queue isn't full.
    func start() {
        guard current.count < maxConcurrentDownloads else { return }
        
        Task.detached(priority: .background) { [self] in
            do {
                // Request downloads | double to help prevent racing overlap
                let downloads = try await data.readFreshDownloads(maxConcurrentDownloads * 2)
                
                /// Add new downloads until the cap is reached or there are no new ones.
                while let download = await newCurrentDownload(from: downloads) {
                    startDownload(for: download)
                }
            } catch {
                print("Failed to read downloads: \(error)")
            }
        }
    }
}

// MARK: Download Helper Functions
extension DownloadManager {
    /// Takes an array of ``EpisodeDownload`` and adds then returns the first value that is NOT currently in use by the manager.
    ///
    /// Returns `nil` when none of the downloads are valid, or when there are already `concurrentDownloads` downloads running.
    private func newCurrentDownload(from episodeDownloads: [EpisodeDownload]) -> EpisodeDownload? {
        guard current.count <= maxConcurrentDownloads else { return nil }
        
        for episodeDownload in episodeDownloads {
            if !current.contains(where: { $0.id == episodeDownload.id }) {
                current.append(episodeDownload)
                return episodeDownload
            }
        }
        
        // No new episode downloads
        return nil
    }
    
    private func removeCurrentDownload(_ download: EpisodeDownload) {
        if let index = current.firstIndex(where: { $0.id == download.id }) {
            current.remove(at: index)
        }
    }
    
    /// Creates a detached background task for a specific episode download.
    private nonisolated func startDownload(for episodeDownload: EpisodeDownload) {
        // TODO: Handle errors in this Task
        Task.detached(priority: .background) { [files, weak self] in
            // Check if the download has already started.
            var byte: Int64 = 0
            if files.fileExists(atPath: episodeDownload.path.string) {
                let attributes = try? files.attributesOfItem(atPath: episodeDownload.path.string)
                byte = (attributes?[.size] as? Int64) ?? 0
            }
            
            var request = try HTTPClient.Request(url: episodeDownload.remote.string)
            if byte > 0 {
                request.headers.add(name: "Range", value: "bytes=\(byte)-")
            }
            
            let delegate = StreamingDownloadDelegate(
                destinationPath: episodeDownload.path.string,
                expectedBytes: nil,
                resumeFromByte: byte,
                onProgress: { [weak self] percent in
                    // Update episode download progress if it has gone past a full percent and is not completed.
                    if episodeDownload.progress - percent > 1 && percent < 99 {
                        Task {
                            try await self?.data.update(episodeDownload)
                        }
                    }
                }
            )
            
            guard let client = self?.client,
                  let timeout = self?.downloadTimeoutSeconds
            else { return }
            
            let result = try await client.execute(
                request: request,
                delegate: delegate,
                deadline: .now() + .seconds(timeout)
            ).futureResult.get()
            
            guard result.success else {
                throw result.error!
            }
            
            episodeDownload.finishedAt = .now
            episodeDownload.progress = 100
            try await self?.data.update(episodeDownload)
            await self?.removeCurrentDownload(episodeDownload)
            
            await self?.start()
        }
    }
}

extension FileManager: @retroactive @unchecked Sendable {
    
}

