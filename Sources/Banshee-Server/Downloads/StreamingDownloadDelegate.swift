import Foundation
import AsyncHTTPClient
import NIOCore
import NIOPosix
import NIOHTTP1

/// Delegate for streaming podcast episode downloads to disk
final class StreamingDownloadDelegate: HTTPClientResponseDelegate {
    typealias Response = DownloadResult

    private let destinationPath: String
    private let expectedBytes: Int64?
    private let onProgress: @Sendable (Double) -> Void
    private let resumeFromByte: Int64

    private var fileHandle: NIOFileHandle?
    private var receivedBytes: Int64 = 0
    private var statusCode: HTTPResponseStatus?
    private let threadPool: NIOThreadPool
    private let fileIO: NonBlockingFileIO

    struct DownloadResult: Sendable {
        let success: Bool
        let bytesWritten: Int64
        let statusCode: HTTPResponseStatus
        let error: (any Error)?
    }

    enum DownloadError: Error {
        case httpError(HTTPResponseStatus)
        case fileIOError(String)
        case cancelled
    }

    init(
        destinationPath: String,
        expectedBytes: Int64?,
        resumeFromByte: Int64 = 0,
        onProgress: @escaping @Sendable (Double) -> Void
    ) {
        self.destinationPath = destinationPath
        self.expectedBytes = expectedBytes
        self.resumeFromByte = resumeFromByte
        self.onProgress = onProgress

        // Initialize thread pool for file I/O
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.threadPool.start()
        self.fileIO = NonBlockingFileIO(threadPool: threadPool)
    }

    func didReceiveHead(
        task: HTTPClient.Task<Response>,
        _ head: HTTPResponseHead
    ) -> EventLoopFuture<Void> {
        self.statusCode = head.status

        // Validate successful response (200 OK or 206 Partial Content for resume)
        guard head.status == .ok || head.status == .partialContent else {
            return task.eventLoop.makeFailedFuture(
                DownloadError.httpError(head.status)
            )
        }

        // Create directory structure if needed
        let directory = (destinationPath as NSString).deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true
            )
        } catch {
            return task.eventLoop.makeFailedFuture(
                DownloadError.fileIOError("Failed to create directory: \(error)")
            )
        }

        // Open file for writing
        do {
            // If resuming, open in append mode, otherwise create new file
            if resumeFromByte > 0 && FileManager.default.fileExists(atPath: destinationPath) {
                // Open for appending
                let fileHandle = try NIOFileHandle(path: destinationPath, mode: .write, flags: .default)
                self.fileHandle = fileHandle
                self.receivedBytes = resumeFromByte
            } else {
                // Create new file
                let fileHandle = try NIOFileHandle(
                    path: destinationPath,
                    mode: .write,
                    flags: .allowFileCreation(posixMode: 0o644)
                )
                self.fileHandle = fileHandle
            }
            return task.eventLoop.makeSucceededFuture(())
        } catch {
            return task.eventLoop.makeFailedFuture(
                DownloadError.fileIOError("Failed to open file: \(error)")
            )
        }
    }

    func didReceiveBodyPart(
        task: HTTPClient.Task<Response>,
        _ buffer: ByteBuffer
    ) -> EventLoopFuture<Void> {
        guard let fileHandle = self.fileHandle else {
            return task.eventLoop.makeFailedFuture(
                DownloadError.fileIOError("File handle not initialized")
            )
        }

        let bytesToWrite = Int64(buffer.readableBytes)
        receivedBytes += bytesToWrite

        // Calculate offset for writing (append at end for resume)
        let writeOffset = resumeFromByte > 0 ? receivedBytes - bytesToWrite : receivedBytes - bytesToWrite

        // Write chunk to disk
        return fileIO.write(
            fileHandle: fileHandle,
            toOffset: writeOffset,
            buffer: buffer,
            eventLoop: task.eventLoop
        ).map { _ in
            // Update progress
            if let expectedBytes = self.expectedBytes, expectedBytes > 0 {
                let progress = Double(self.receivedBytes) / Double(expectedBytes)
                self.onProgress(min(progress, 1.0))
            }
        }
    }

    func didFinishRequest(task: HTTPClient.Task<Response>) throws -> Response {
        // Close file handle
        try? fileHandle?.close()

        // Shutdown thread pool
        threadPool.shutdownGracefully { _ in }

        guard let statusCode = statusCode else {
            throw DownloadError.fileIOError("No response received")
        }

        // Final progress update
        onProgress(1.0)

        return DownloadResult(
            success: statusCode == .ok || statusCode == .partialContent,
            bytesWritten: receivedBytes,
            statusCode: statusCode,
            error: nil
        )
    }

    func didReceiveError(task: HTTPClient.Task<Response>, _ error: any Error) {
        // Cleanup on error
        try? fileHandle?.close()

        // Shutdown thread pool
        threadPool.shutdownGracefully { _ in }

        // Don't delete partial file to allow resume
    }
}
