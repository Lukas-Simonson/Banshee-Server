import Fluent
import Vapor

final class Episode: Model, @unchecked Sendable {
    @ID
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "pubDate")
    var pubDate: Date

    @Field(key: "description")
    var description: String

    @Field(key: "season")
    var season: String?

    @Field(key: "episodeNumber")
    var episodeNumber: Int?

    @Parent(key: "podcastID")
    var podcast: Podcast

    @OptionalChild(for: \.$episode)
    var config: EpisodeConfig?

    @OptionalChild(for: \.$episode)
    var audioConfig: AudioConfig?
}

extension Episode {
    func update(from dto: RSS.EpisodeDTO) {
        self.title = dto.title
        self.pubDate = dto.pubDate
        self.description = dto.description
        self.season = dto.season
        self.episodeNumber = dto.episode 
    }

    static func != (lhs: Episode, rhs: RSS.EpisodeDTO) -> Bool {
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
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("episode")
                .id()
                .field("title", .string, .required)
                .field("pubDate", .datetime, .required)
                .field("description", .string, .required)
                .field("season", .string)
                .field("episodeNumber", .int64)
                .field("podcastID", .uuid, .references("podcast", "id", onDelete: .cascade))
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("episode").delete()
        }
    }
}