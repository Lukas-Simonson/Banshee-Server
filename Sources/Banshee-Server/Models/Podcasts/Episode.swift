import Fluent
import Vapor

final class Episode: Model, @unchecked Sendable {
    @ID
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "pubDate")
    var pubDate: Date

    @Group(key: "audioEnclosure")
    var audioEnclosure: AudioEnclosure

    @Field(key: "description")
    var description: String

    @Parent(key: "podcastID")
    var podcast: Podcast

    @OptionalChild(for: \.$episode)
    var config: EpisodeConfig?
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
                .field("audioEnclosure_url", .string, .required)
                .field("audioEnclosure_length", .int64)
                .field("audioEnclosure_type", .string, .required)
                .field("description", .string, .required)
                .field("podcastID", .uuid, .references("podcast", "id", onDelete: .cascade))
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("episode").delete()
        }
    }
}