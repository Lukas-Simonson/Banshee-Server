import Foundation

/// Represents a request to download a file from a remote URL to a local destination
struct DownloadRequest: Sendable, Hashable {
    /// Unique identifier for this download request
    let id: UUID

    /// Remote URL to download from
    let remoteURL: URL

    /// Local file system path where the file should be saved
    let destinationPath: String

    /// Expected file size in bytes (optional, used for progress tracking)
    let expectedBytes: Int64?

    /// Optional metadata for user's tracking purposes
    let metadata: [String: String]?

    init(
        id: UUID = UUID(),
        remoteURL: URL,
        destinationPath: String,
        expectedBytes: Int64? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.remoteURL = remoteURL
        self.destinationPath = destinationPath
        self.expectedBytes = expectedBytes
        self.metadata = metadata
    }
}
