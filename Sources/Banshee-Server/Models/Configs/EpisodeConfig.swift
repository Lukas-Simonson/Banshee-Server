import Fluent
import Vapor

final class EpisodeConfig: Model, @unchecked Sendable {
    @ID
    var id: UUID?

    @Field(key: "title")
    var title: String?

    @Field(key: "description")
    var description: String?

    @Field(key: "imageURL")
    var imageURL: URL?

    @Field(key: "season")
    var season: String?

    @Field(key: "episodeNumber")
    var episodeNumber: Int?

    @Parent(key: "episodeID")
    var episode: Episode
}

// MARK: - Model Conformance
extension EpisodeConfig {
    static let schema = "episodeConfig"

    enum Migration { }
}

extension EpisodeConfig.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("episodeConfig")
                .id()
                .field("title", .string)
                .field("description", .string)
                .field("imageURL", .string)
                .field("season", .string)
                .field("episodeNumber", .int64)
                .field("episodeID", .uuid, .references("episode", "id", onDelete: .cascade))
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("episodeConfig").delete()
        }
    }
}