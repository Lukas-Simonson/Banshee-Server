import Vapor
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import Foundation

/// Manages large file downloads with streaming, concurrency control, and resume support
actor DownloadManager {

    /// Current Download Tasks, keyed by the download request ID
    private(set) var tasks = [UUID: FileDownload]()

    /// Base directory for episode storage
    let storageBasePath: String

    /// The logger to use for logging
    private var logger: Logger?

    /// Dedicated HTTP client for streaming downloads
    private let httpClient: HTTPClient

    /// Maximum number of concurrent downloads
    private let maxConcurrentDownloads: Int = 3

    /// Current number of active downloads
    private var activeCount: Int = 0

    /// Queue of pending downloads waiting for a slot
    private var pendingQueue: [DownloadRequest] = []

    init(storageBasePath: String = "Storage/episodes", logger: Logger?) {
        self.storageBasePath = storageBasePath
        self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        self.logger = logger
    }

    deinit {
        try? httpClient.syncShutdown()
    }

    /// Queues file downloads from a remote URL to local storage. 
    /// 
    /// Queues each request in a Task to provide a non-blocking approach.
    /// 
    /// - Parameter requests: An Array of request containing a remote URL and destination path.
    /// - Throws: DownloadError if download fails or is already in progress.
    func download(_ requests: [DownloadRequest]) async throws {
        for request in requests {
            if tasks[request.id] != nil {
                throw DownloadError.alreadyDownloading(request.id)
            }

            if activeCount >= maxConcurrentDownloads {
                pendingQueue.append(request)
                return
            }

            Task {
                logger?.info("Starting download for \(request.destinationPath)")
                do { try await startDownload(request) }
                catch { logger?.error("\(error)") }
            }
        }
    }

    /// Downloads a file from a remote URL to local storage
    /// - Parameter request: Download request containing remote URL and destination path
    /// - Throws: DownloadError if download fails or already in progress
    func download(_ request: DownloadRequest) async throws {
        // Check if already downloading
        if tasks[request.id] != nil {
            throw DownloadError.alreadyDownloading(request.id)
        }

        // Check if at concurrency limit
        if activeCount >= maxConcurrentDownloads {
            // Add to queue
            pendingQueue.append(request)
            return
        }

        // Start download
        try await startDownload(request)
    }

    /// Cancels an active download
    func cancelDownload(id: UUID) async {
        guard let download = tasks[id] else { return }

        download.task.cancel()
        download.updateStatus(.cancelled)

        // Cleanup partial file
        try? FileManager.default.removeItem(atPath: download.request.destinationPath)

        tasks.removeValue(forKey: id)
        activeCount -= 1

        // Process next in queue
        processNextInQueue()
    }

    /// Gets current download progress for a request
    func getProgress(id: UUID) -> Double? {
        tasks[id]?.progress
    }

    /// Lists all active downloads
    func activeDownloads() -> [UUID: Double] {
        tasks.mapValues { $0.progress }
    }

    // MARK: - Private Helpers

    private func startDownload(_ request: DownloadRequest) async throws {
        activeCount += 1

        // Create download task
        let downloadTask = Task<Void, any Error> {
            try await self.performDownloadWithRetry(request: request)
        }

        // Track download
        let fileDownload = FileDownload(
            request: request,
            task: downloadTask
        )

        tasks[request.id] = fileDownload

        // Await completion
        do {
            try await downloadTask.value
            fileDownload.updateStatus(.completed)
        } catch is CancellationError {
            fileDownload.updateStatus(.cancelled)
        } catch {
            fileDownload.updateStatus(.failed(error))
            throw error
        }

        tasks.removeValue(forKey: request.id)
        activeCount -= 1

        // Process next in queue
        processNextInQueue()
    }

    private func processNextInQueue() {
        guard !pendingQueue.isEmpty, activeCount < maxConcurrentDownloads else { return }

        let request = pendingQueue.removeFirst()

        Task {
            try await self.download(request)
        }
    }

    private func performDownloadWithRetry(
        request: DownloadRequest,
        maxRetries: Int = 3
    ) async throws {
        var attempt = 0
        var lastError: (any Error)?

        while attempt < maxRetries {
            do {
                try await performDownload(request: request)
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

    private func performDownload(request: DownloadRequest) async throws {
        // Check for existing partial file to enable resume
        var resumeFromByte: Int64 = 0
        if FileManager.default.fileExists(atPath: request.destinationPath) {
            let attrs = try? FileManager.default.attributesOfItem(atPath: request.destinationPath)
            resumeFromByte = (attrs?[.size] as? Int64) ?? 0
        }

        // Create HTTP request
        var httpRequest = try HTTPClient.Request(url: request.remoteURL.absoluteString)

        // Add Range header for resume if needed
        if resumeFromByte > 0 {
            httpRequest.headers.add(name: "Range", value: "bytes=\(resumeFromByte)-")
        }

        // Create delegate with progress callback
        let delegate = StreamingDownloadDelegate(
            destinationPath: request.destinationPath,
            expectedBytes: request.expectedBytes,
            resumeFromByte: resumeFromByte
        ) { [weak self] progress in
            Task {
                await self?.updateProgress(id: request.id, progress: progress)
            }
        }

        // Execute download with timeout
        let result = try await httpClient.execute(
            request: httpRequest,
            delegate: delegate,
            deadline: .now() + .seconds(3600) // 1 hour timeout for large files
        ).futureResult.get()

        guard result.success else {
            throw result.error ?? DownloadError.downloadFailed("Download failed with status \(result.statusCode)")
        }
    }

    private func updateProgress(id: UUID, progress: Double) {
        tasks[id]?.updateProgress(progress)
    }

    // MARK: - Error Types

    enum DownloadError: Error, CustomStringConvertible {
        case alreadyDownloading(UUID)
        case downloadFailed(String)

        var description: String {
            switch self {
            case .alreadyDownloading(let id):
                return "Download \(id) is already in progress"
            case .downloadFailed(let message):
                return "Download failed: \(message)"
            }
        }
    }
}
