import Fluent
import Vapor

final class Episode: Model, @unchecked Sendable {
    @ID
    var id: UUID?
    
    @Field(key: "guid")
    var guid: String

    @Field(key: "title")
    var title: String

    @Field(key: "pub_date")
    var pubDate: Date

    @Field(key: "description")
    var description: String

    @Field(key: "season")
    var season: String?

    @Field(key: "episode_number")
    var episodeNumber: Int?
    
    @Field(key: "duration")
    var duration: Int?
    
    @Group(key: "audio")
    var audio: Audio
    
    @Group(key: "config")
    var config: EpisodeConfig
    
    @Children(for: \.$episode)
    var progresses: [EpisodeProgress]

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
    }
}

// MARK: - Model Conformance
extension Episode {
    static let schema = "episode"

    enum Migration { }
}

extension Episode.Migration {
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
