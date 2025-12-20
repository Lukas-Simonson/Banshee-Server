import Fluent
import Vapor

final class RSSConfig: Model, @unchecked Sendable {
    @ID
    var id: UUID?

    @Field(key: "url")
    var url: URL

    @Field(key: "lastFetched")
    var lastFetched: Date

    @Field(key: "updateInterval")
    var updateInterval: TimeInterval?

    @Parent(key: "podcastID")
    var podcast: Podcast

    init() {}
    
    /// Creates an RSSConfig with default options.
    convenience init(url: URL) {
        self.init()
        
        self.url = url
        self.lastFetched = .now
        self.updateInterval = 86_400 // 1 day
    }
}

// MARK: Model Conformance
extension RSSConfig {
    static let schema = "rssConfig"

    enum Migration { }
}

extension RSSConfig.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("rssConfig")
                .id()
                .field("url", .string, .required)
                .field("lastFetched", .datetime, .required)
                .field("updateInterval", .double)
                .field("podcastID", .uuid, .required, .references("podcast", "id", onDelete: .cascade))
                .unique(on: "url") // Unique RSS Feeds
                .unique(on: "podcastID")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("rssConfig").delete()
        }
    }
}