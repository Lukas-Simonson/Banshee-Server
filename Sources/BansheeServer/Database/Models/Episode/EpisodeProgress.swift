import Fluent
import Vapor

/// The progress for a given user for a given episode.
final class EpisodeProgress: Model, @unchecked Sendable {
    
    /// The unique identifier used by the server.
    @ID
    var id: UUID?
    
    /// Whether or not the episode has been completed.
    @Field(key: "is_completed")
    var isCompleted: Bool
    
    /// How long, in seconds, the user has listened to the episode.
    @Field(key: "watch_time")
    var watchTime: Int
    
    /// When the user initially started listening to the episode.
    @Field(key: "started_on")
    var startedOn: Date
    
    /// The last time this progress was updated.
    @Field(key: "last_updated")
    var lastUpdated: Date
    
    /// The user this progress is for.
    @Parent(key: "user_id")
    var user: User
    
    /// The episode this progress is for.
    @Parent(key: "episode_id")
    var episode: Episode
    
    init() {}
    
    init(isCompleted: Bool, watchTime: Int, startedOn: Date, lastUpdated: Date) {
        self.id = id
        self.isCompleted = isCompleted
        self.watchTime = watchTime
        self.startedOn = startedOn
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Model Conformance
extension EpisodeProgress {
    static let schema = "episode_progress"
    
    enum Migration { }
}

extension EpisodeProgress.Migration {
    
    /// Creates the episode progress table.
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("episode_progress")
                .id()
                .field("is_completed", .bool, .required)
                .field("watch_time", .int64, .required)
                .field("started_on", .datetime, .required)
                .field("last_updated", .datetime, .required)
                .field("user_id", .uuid, .references("user", "id", onDelete: .cascade), .required)
                .field("episode_id", .uuid, .references("episode", "id", onDelete: .cascade), .required)
                .unique(on: "user_id", "episode_id")
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("episode_progress").delete()
        }
    }
}
