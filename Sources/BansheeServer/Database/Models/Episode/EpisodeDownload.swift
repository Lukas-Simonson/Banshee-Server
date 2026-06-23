import Fluent
import Vapor

/// A file download request / result for an ``Episode``.
final class EpisodeDownload: Model, @unchecked Sendable {
    
    /// The unique identifier used by the server.
    @ID
    var id: UUID?
    
    /// The local path this download is saved to.
    @Field(key: "path")
    var path: URI
    
    /// The remote location this download should be saved from.
    @Field(key: "remote")
    var remote: URI
    
    /// How much progress has been made on this download.
    @Field(key: "progress")
    var progress: Double
    
    /// What time the download was originally queued at.
    @Timestamp(key: "queued_at", on: .create)
    var queuedAt: Date?
    
    /// When the download finished downloading.
    @OptionalField(key: "finished_at")
    var finishedAt: Date?
    
    /// The episode this download belongs to.
    ///
    /// Optional as to allow knowing when we have a download for an episode that we no longer have.
    @OptionalParent(key: "episode_id")
    var episode: Episode?
    
    init() {}
    
    init(id: UUID? = nil, path: URI, remote: URI, episode: Episode) {
        self.id = id
        self.path = path
        self.remote = remote
        self.progress = 0.0
        self.episode = episode
    }
}

extension EpisodeDownload {
    static let schema = "episode_download"
    
    enum Migration { }
}

extension EpisodeDownload.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("episode_download")
                .id()
                .field("path", .string, .required).unique(on: "path")
                .field("remote", .string, .required).unique(on: "remote")
                .field("progress", .double, .required)
                .field("queued_at", .datetime)
                .field("finished_at", .datetime)
                .field("episode_id", .uuid, .references("episode", "id", onDelete: .setNull)).unique(on: "episode_id")
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("episode_download").delete()
        }
    }
}
