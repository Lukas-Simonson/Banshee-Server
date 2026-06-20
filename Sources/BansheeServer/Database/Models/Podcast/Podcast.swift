import Fluent
import Vapor

final class Podcast: Model, @unchecked Sendable {
    
    /// The unique identifier used by the server.
    @ID
    var id: UUID?
    
    /// The title of the podcast.
    @Field(key: "title")
    var title: String
    
    /// A link provided from the RSS feed, for accessing information about the podcast.
    @OptionalField(key: "link")
    var link: URI?
    
    /// The language the podcast is recorded in.
    @Field(key: "language")
    var language: String
    
    /// The cover art to use for this podcast.
    @OptionalField(key: "image_url")
    var imageURL: URI?
    
    /// The description of the podcast.
    @Field(key: "description")
    var description: String
    
    /// The non-destructive server config of the episode.
    @Group(key: "config")
    var config: PodcastConfig
    
    /// The episodes that belong to this podcast.
    @Children(for: \.$podcast)
    var episodes: [Episode]
    
    /// The RSS Feed that provides information about this podcast.
    @OptionalChild(for: \.$podcast)
    var feed: RSSFeed?
    
    init() {}
    
    init(title: String, link: URI?, language: String, imageURL: URI?, description: String, config: PodcastConfig? = nil) {
        self.title = title
        self.link = link
        self.language = language
        self.imageURL = imageURL
        self.description = description
        self.config = config ?? PodcastConfig(title: nil, imageURL: nil, description: nil)
    }
}

extension Podcast {
    static let schema = "podcast"
    
    enum Migration { }
}

extension Podcast.Migration {
    
    /// Creates the podcast table.
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("podcast")
                .id()
                .field("title", .string, .required)
                .field("link", .string)
                .field("language", .string, .required)
                .field("image_url", .string)
                .field("description", .string, .required)
                .field("config_title", .string)
                .field("config_image_url", .string)
                .field("config_description", .string)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("podcast").delete()
        }
    }
}
