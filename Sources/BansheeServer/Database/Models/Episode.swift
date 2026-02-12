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
    
    @Field(key: "duration")
    var duration: Int?

    @Parent(key: "podcastID")
    var podcast: Podcast
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
                .field("duration", .int64)
                .field("podcastID", .uuid, .references("podcast", "id", onDelete: .cascade), .required)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("episode").delete()
        }
    }
}
