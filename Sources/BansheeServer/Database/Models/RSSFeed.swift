import Fluent
import Vapor

final class RSSFeed: Model, @unchecked Sendable {
    @ID
    var id: UUID?
    
    @Field(key: "url")
    var url: URI
    
    @Field(key: "last_fetched")
    var lastFetched: Date
    
    @Field(key: "update_interval")
    var updateInterval: TimeInterval?
    
    @Parent(key: "podcast_id")
    var podcast: Podcast
    
    init() { }
    
    init(url: URI) {
        self.url = url
        self.lastFetched = .now
        self.updateInterval = 86_400 // 1 day
    }
}

extension RSSFeed {
    static let schema = "rss_feed"
    
    enum Migration { }
}

extension RSSFeed.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("rss_feed")
                .id()
                .field("url", .string, .required)
                .field("last_fetched", .datetime, .required)
                .field("update_interval", .double)
                .field("podcast_id", .uuid, .required, .references("podcast", "id", onDelete: .cascade))
                .unique(on: "url") // Unique RSS Feeds
                .unique(on: "podcast_id")
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("rss_feed").delete()
        }
    }
}
