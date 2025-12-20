import Vapor
import Fluent
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import Foundation

/// Manages large file downloads, specifically focused on Podcast Episodes
actor DownloadManager {

    /// Current Download Tasks, keyed by the id of the episode that is being downloaded.
    private(set) var tasks = [UUID: FileDownload]()

    /// Dedicated HTTP client for streaming downloads
    private let httpClient: HTTPClient

    /// Base directory for episode storage
    private let storageBasePath: String

    /// Maximum number of concurrent downloads
    private let maxConcurrentDownloads: Int = 3

    /// Current number of active downloads
    private var activeCount: Int = 0

    /// Queue of pending downloads waiting for a slot
    private var pendingQueue: [(Episode, any Database)] = []

    init(storageBasePath: String = "Storage/episodes") {
        self.storageBasePath = storageBasePath
        self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    }

    deinit {
        try? httpClient.syncShutdown()
    }

    /// Downloads a podcast episode from its remote URL to local storage
    /// - Parameters:
    ///   - episode: Episode to download (must have audioConfig with remoteURL)
    ///   - db: Database connection for updating AudioConfig
    /// - Throws: DownloadError if download fails or prerequisites not met
    func download(episode: Episode, db: any Database) async throws {
        // Validate episode has audio config with remote URL
        guard let audioConfig = episode.audioConfig else {
            throw DownloadError.missingAudioConfig
        }

        guard let episodeID = episode.id else {
            throw DownloadError.missingEpisodeID
        }

        guard let remoteURL = audioConfig.remoteURL else {
            throw DownloadError.missingRemoteURL
        }

        // Check if already downloading
        if tasks[episodeID] != nil {
            throw DownloadError.alreadyDownloading(episodeID)
        }

        // Check if at concurrency limit
        if activeCount >= maxConcurrentDownloads {
            // Add to queue
            pendingQueue.append((episode, db))
            return
        }

        // Start download
        try await startDownload(episode: episode, audioConfig: audioConfig, episodeID: episodeID, remoteURL: remoteURL, db: db)
    }

    /// Cancels an active download
    func cancelDownload(episodeID: UUID) async {
        guard let download = tasks[episodeID] else { return }

        download.task.cancel()
        download.updateStatus(.cancelled)

        // Cleanup partial file
        try? FileManager.default.removeItem(at: download.to)

        tasks.removeValue(forKey: episodeID)
        activeCount -= 1

        // Process next in queue
        processNextInQueue()
    }

    /// Gets current download progress for an episode
    func getProgress(episodeID: UUID) -> Double? {
        tasks[episodeID]?.progress
    }

    /// Lists all active downloads
    func activeDownloads() -> [UUID: Double] {
        tasks.mapValues { $0.progress }
    }

    // MARK: - Private Helpers

    private func startDownload(
        episode: Episode,
        audioConfig: AudioConfig,
        episodeID: UUID,
        remoteURL: URL,
        db: any Database
    ) async throws {
        activeCount += 1

        // Determine destination path
        let filename = sanitizeFilename(extractFilename(from: remoteURL, mimeType: audioConfig.type))
        let destinationPath = "\(storageBasePath)/\(episodeID)/\(filename)"
        let destinationURL = URL(fileURLWithPath: destinationPath)

        // Create download task
        let downloadTask = Task<Void, any Error> {
            try await self.performDownloadWithRetry(
                episodeID: episodeID,
                remoteURL: remoteURL,
                destinationPath: destinationPath,
                expectedBytes: audioConfig.length,
                db: db
            )
        }

        // Track download
        let fileDownload = FileDownload(
            id: episodeID,
            from: remoteURL,
            to: destinationURL,
            task: downloadTask
        )

        tasks[episodeID] = fileDownload

        // Await completion
        do {
            try await downloadTask.value

            // Update database with local URL
            audioConfig.localURL = destinationURL
            try await audioConfig.update(on: db)

            fileDownload.updateStatus(.completed)
        } catch is CancellationError {
            fileDownload.updateStatus(.cancelled)
        } catch {
            fileDownload.updateStatus(.failed(error))
            throw error
        }

        tasks.removeValue(forKey: episodeID)
        activeCount -= 1

        // Process next in queue
        processNextInQueue()
    }

    private func processNextInQueue() {
        guard !pendingQueue.isEmpty, activeCount < maxConcurrentDownloads else { return }

        let (episode, db) = pendingQueue.removeFirst()

        Task {
            try await self.download(episode: episode, db: db)
        }
    }

    private func performDownloadWithRetry(
        episodeID: UUID,
        remoteURL: URL,
        destinationPath: String,
        expectedBytes: Int64?,
        db: any Database,
        maxRetries: Int = 3
    ) async throws {
        var attempt = 0
        var lastError: (any Error)?

        while attempt < maxRetries {
            do {
                try await performDownload(
                    episodeID: episodeID,
                    remoteURL: remoteURL,
                    destinationPath: destinationPath,
                    expectedBytes: expectedBytes
                )
                return
            } catch let error as StreamingDownloadDelegate.DownloadError {
                lastError = error

                // Don't retry on client errors (4xx)
                if case .httpError(let status) = error, (400..<500).contains(Int(status.code)) {
                    throw error
                }

                attempt += 1

                if attempt < maxRetries {
                    // Exponential backoff with max 60 seconds
                    let delay = min(pow(2.0, Double(attempt)), 60.0)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                lastError = error
                attempt += 1

                if attempt < maxRetries {
                    let delay = min(pow(2.0, Double(attempt)), 60.0)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? DownloadError.downloadFailed("Unknown error after \(maxRetries) retries")
    }

    private func performDownload(
        episodeID: UUID,
        remoteURL: URL,
        destinationPath: String,
        expectedBytes: Int64?
    ) async throws {
        // Check for existing partial file to enable resume
        var resumeFromByte: Int64 = 0
        if FileManager.default.fileExists(atPath: destinationPath) {
            let attrs = try? FileManager.default.attributesOfItem(atPath: destinationPath)
            resumeFromByte = (attrs?[.size] as? Int64) ?? 0
        }

        // Create HTTP request
        var request = try HTTPClient.Request(url: remoteURL.absoluteString)

        // Add Range header for resume if needed
        if resumeFromByte > 0 {
            request.headers.add(name: "Range", value: "bytes=\(resumeFromByte)-")
        }

        // Create delegate with progress callback
        let delegate = StreamingDownloadDelegate(
            destinationPath: destinationPath,
            expectedBytes: expectedBytes,
            resumeFromByte: resumeFromByte
        ) { [weak self] progress in
            Task {
                await self?.updateProgress(episodeID: episodeID, progress: progress)
            }
        }

        // Execute download with timeout
        let result = try await httpClient.execute(
            request: request,
            delegate: delegate,
            deadline: .now() + .seconds(3600) // 1 hour timeout for large files
        ).futureResult.get()

        guard result.success else {
            throw result.error ?? DownloadError.downloadFailed("Download failed with status \(result.statusCode)")
        }
    }

    private func updateProgress(episodeID: UUID, progress: Double) {
        tasks[episodeID]?.updateProgress(progress)
    }

    private func extractFilename(from url: URL, mimeType: String?) -> String {
        // Try to get filename from URL
        let urlFilename = url.lastPathComponent

        // Validate it has an extension
        if urlFilename.contains(".") && !urlFilename.hasSuffix(".") {
            return urlFilename
        }

        // Fallback to UUID with appropriate extension
        let ext = extensionForMimeType(mimeType) ?? "mp3"
        return "\(UUID().uuidString).\(ext)"
    }

    private func extensionForMimeType(_ mimeType: String?) -> String? {
        guard let mimeType = mimeType?.lowercased() else { return nil }

        switch mimeType {
        case "audio/mpeg", "audio/mp3": return "mp3"
        case "audio/mp4", "audio/m4a": return "m4a"
        case "audio/x-m4a": return "m4a"
        case "audio/ogg": return "ogg"
        case "audio/wav": return "wav"
        case "audio/aac": return "aac"
        case "audio/flac": return "flac"
        default: return nil
        }
    }

    private func sanitizeFilename(_ filename: String) -> String {
        // Remove path separators and prevent directory traversal
        filename
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: "..", with: "_")
    }

    // MARK: - Error Types

    enum DownloadError: Error, CustomStringConvertible {
        case missingAudioConfig
        case missingEpisodeID
        case missingRemoteURL
        case alreadyDownloading(UUID)
        case downloadFailed(String)
        case insufficientDiskSpace

        var description: String {
            switch self {
            case .missingAudioConfig:
                return "Episode does not have audio configuration"
            case .missingEpisodeID:
                return "Episode missing ID"
            case .missingRemoteURL:
                return "Audio config missing remote URL"
            case .alreadyDownloading(let id):
                return "Episode \(id) is already downloading"
            case .downloadFailed(let message):
                return "Download failed: \(message)"
            case .insufficientDiskSpace:
                return "Insufficient disk space for download"
            }
        }
    }
}
