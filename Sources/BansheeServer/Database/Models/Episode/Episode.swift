import Fluent
import Vapor

/// A podcast episode.
final class Episode: Model, @unchecked Sendable {
    
    /// The unique identifier used by the server.
    @ID
    var id: UUID?
    
    /// The globally unique identifier used by rss feeds.
    @Field(key: "guid")
    var guid: String

    /// The title of the episode.
    @Field(key: "title")
    var title: String

    /// The date the episode was published.
    @Field(key: "pub_date")
    var pubDate: Date

    /// The description of the episode.
    @Field(key: "description")
    var description: String

    /// The season of the episode.
    @Field(key: "season")
    var season: String?

    /// The episode number.
    @OptionalField(key: "episode_number")
    var episodeNumber: Int?
    
    /// How long, in seconds, the episode is.
    @OptionalField(key: "duration")
    var duration: Int?
    
    /// The audio information of the episode.
    @Group(key: "audio")
    var audio: Audio
    
    /// The non-destructive server config of the episode.
    @Group(key: "config")
    var config: EpisodeConfig
    
    /// Progress for all accounts on this episode.
    @Children(for: \.$episode)
    var progresses: [EpisodeProgress]
    
    @OptionalChild(for: \.$episode)
    var download: EpisodeDownload?

    /// The podcast this episode belongs to.
    @Parent(key: "podcast_id")
    var podcast: Podcast
    
    init() {}
    
    init(
        guid: String,
        title: String,
        pubDate: Date,
        description: String,
        season: String? = nil,
        episodeNumber: Int? = nil,
        duration: Int? = nil,
        audio: Audio
    ) {
        self.guid = guid
        self.title = title
        self.pubDate = pubDate
        self.description = description
        self.season = season
        self.episodeNumber = episodeNumber
        self.duration = duration
        self.audio = audio
        self.config = EpisodeConfig(
            title: nil,
            description: nil,
            imageURL: nil,
            season: nil,
            episodeNumber: nil
        )
    }
}

extension Episode {
    
    /// Updates the episode with all new values from an ``EpisodeRSS``
    func update(from dto: EpisodeRSS) {
        self.title = dto.title
        self.pubDate = dto.pubDate
        self.description = dto.description
        self.season = dto.season
        self.episodeNumber = dto.episode
        self.duration = dto.duration?.seconds
    }

    static func != (lhs: Episode, rhs: EpisodeRSS) -> Bool {
        lhs.title != rhs.title || lhs.pubDate != rhs.pubDate ||
        lhs.description != rhs.description || lhs.season != rhs.season ||
        lhs.episodeNumber != rhs.episode
    }
}


// MARK: - Model Conformance
extension Episode {
    static let schema = "episode"

    enum Migration { }
}

extension Episode.Migration {
    
    /// Creates the episode table.
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("episode")
                .id()
                .field("guid", .string, .required).unique(on: "guid")
                .field("title", .string, .required)
                .field("pub_date", .datetime, .required)
                .field("description", .string, .required)
                .field("season", .string)
                .field("episode_number", .int64)
                .field("duration", .int64)
                .field("podcast_id", .uuid, .references("podcast", "id", onDelete: .cascade), .required)
            
                // Audio Group
                .field("audio_remote_url", .string)
                .field("audio_local_url", .string)
                .field("audio_length", .int64)
                .field("audio_type", .string)
            
                // Config Group
                .field("config_title", .string)
                .field("config_description", .string)
                .field("config_image_url", .string)
                .field("config_season", .string)
                .field("config_episode_number", .int64)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("episode").delete()
        }
    }
}
