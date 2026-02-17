import Fluent
import Vapor

final class EpisodeProgress: Model, @unchecked Sendable {
    @ID
    var id: UUID?
    
    @Field(key: "is_completed")
    var isCompleted: Bool
    
    @Field(key: "watch_time")
    var watchTime: Int
    
    @Field(key: "started_on")
    var startedOn: Date
    
    @Field(key: "last_updated")
    var lastUpdated: Date
    
    @Parent(key: "user_id")
    var user: User
    
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
