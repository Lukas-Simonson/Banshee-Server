import Fluent
import Vapor

/// An RSS Feed.
final class RSSFeed: Model, @unchecked Sendable {
    
    /// The unique identifier used by the server.
    @ID
    var id: UUID?
    
    /// The url where the RSS feed can be read from.
    @Field(key: "url")
    var url: URI
    
    /// The date of the last time the server updated using the feed.
    @Field(key: "last_fetched")
    var lastFetched: Date
    
    /// How long to wait between updates of the rss feed.
    /// Defaults to 1 day.
    @OptionalField(key: "update_interval")
    var updateInterval: TimeInterval?
    
    /// If new episodes should be downloaded when they are fetched.
    @Field(key: "download_new")
    var downloadNew: Bool
    
    /// The podcast this rss feed is used to fetch.
    @Parent(key: "podcast_id")
    var podcast: Podcast
    
    var isExpired: Bool {
        guard let updateInterval else { return false }
        return lastFetched.advanced(by: updateInterval) < .now
    }
    
    init() { }
    
    init(url: URI, downloadNew: Bool) {
        self.url = url
        self.downloadNew = downloadNew
        self.lastFetched = .now
        self.updateInterval = 86_400 // 1 day
    }
}

extension RSSFeed {
    static let schema = "rss_feed"
    
    enum Migration { }
}

extension RSSFeed.Migration {
    
    /// Creates the RSSFeed table.
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("rss_feed")
                .id()
                .field("url", .string, .required)
                .field("last_fetched", .datetime, .required)
                .field("update_interval", .double)
                .field("download_new", .bool, .required)
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
