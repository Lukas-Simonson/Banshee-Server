import Foundation
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import NIOFileSystem
import SystemPackage

/// Delegate for streaming podcast episode downloads to disk using modern NIOFileSystem
final class StreamingDownloadDelegate: HTTPClientResponseDelegate, @unchecked Sendable {
    typealias Response = DownloadResult

    private let destinationPath: String
    private let expectedBytes: Int64?
    private let onProgress: @Sendable (Double) -> Void
    private let resumeFromByte: Int64

    private let fileSystem: FileSystem
    private var fileHandle: WriteFileHandle?
    private var bufferedWriter: BufferedWriter<WriteFileHandle>?
    private var receivedBytes: Int64 = 0
    private var statusCode: HTTPResponseStatus?

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
        self.fileSystem = .shared
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

        let promise = task.eventLoop.makePromise(of: Void.self)

        Task {
            do {
                // Create directory structure
                let filePath = FilePath(self.destinationPath)
                let directory = filePath.removingLastComponent()
                try await self.fileSystem.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )

                // Determine open options based on resume
                let options: OpenOptions.Write
                if self.resumeFromByte > 0 {
                    // Resume: modify existing file
                    options = .modifyFile(createIfNecessary: true)
                } else {
                    // New file
                    options = .newFile(
                        replaceExisting: false,
                        permissions: FilePermissions(rawValue: 0o644)
                    )
                }

                // Open file
                let handle = try await self.fileSystem.openFile(
                    forWritingAt: filePath,
                    options: options
                )

                self.fileHandle = handle

                // Create buffered writer starting at resume offset
                self.bufferedWriter = handle.bufferedWriter(
                    startingAtAbsoluteOffset: self.resumeFromByte,
                    capacity: .kibibytes(512)
                )

                self.receivedBytes = self.resumeFromByte

                promise.succeed(())
            } catch {
                promise.fail(DownloadError.fileIOError("Failed to prepare file: \(error)"))
            }
        }

        return promise.futureResult
    }

    func didReceiveBodyPart(
        task: HTTPClient.Task<Response>,
        _ buffer: ByteBuffer
    ) -> EventLoopFuture<Void> {
        guard var writer = self.bufferedWriter else {
            return task.eventLoop.makeFailedFuture(
                DownloadError.fileIOError("File writer not initialized")
            )
        }

        let bytesToWrite = Int64(buffer.readableBytes)
        let promise = task.eventLoop.makePromise(of: Void.self)

        Task {
            do {
                // Write chunk using buffered writer
                try await writer.write(contentsOf: buffer.readableBytesView)

                // Update state
                self.receivedBytes += bytesToWrite
                self.bufferedWriter = writer // Save updated writer

                // Update progress
                if let expectedBytes = self.expectedBytes, expectedBytes > 0 {
                    let progress = Double(self.receivedBytes) / Double(expectedBytes)
                    self.onProgress(min(progress, 1.0))
                }

                promise.succeed(())
            } catch {
                promise.fail(error)
            }
        }

        return promise.futureResult
    }

    func didFinishRequest(task: HTTPClient.Task<Response>) throws -> Response {
        guard let statusCode = self.statusCode else {
            throw DownloadError.fileIOError("No response received")
        }

        // Final progress update
        self.onProgress(1.0)

        // Cleanup asynchronously without blocking the event loop
        Task {
            do {
                // Flush remaining buffered data
                try await self.bufferedWriter?.flush()

                // Close file handle
                try await self.fileHandle?.close()
            } catch {
                // Log error but don't fail the download since data is already written
                print("Warning: Failed to close file handle: \(error)")
            }
        }

        // Return result immediately without waiting
        return DownloadResult(
            success: statusCode == .ok || statusCode == .partialContent,
            bytesWritten: self.receivedBytes,
            statusCode: statusCode,
            error: nil
        )
    }

    func didReceiveError(task: HTTPClient.Task<Response>, _ error: any Error) {
        Task {
            // Close file handle
            try? await self.fileHandle?.close()

            // Don't delete partial file to allow resume
        }
    }
}
