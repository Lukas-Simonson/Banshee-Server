import Fluent
import Foundation

final class PodcastConfig: Model, @unchecked Sendable {
    @ID
    var id: UUID?

    @Field(key: "title")
    var title: String?

    @Field(key: "imageURL")
    var imageURL: URL?

    @Field(key: "description")
    var description: String?

    @Parent(key: "podcastID")
    var podcast: Podcast
}

// MARK: - Model Conformance
extension PodcastConfig {
    static let schema = "podcastConfig"

    enum Migration { }
}

extension PodcastConfig.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("podcastConfig")
                .id()
                .field("title", .string)
                .field("imageURL", .string)
                .field("description", .string)
                .field("podcastID", .uuid, .required, .references("podcast", "id", onDelete: .cascade))
                .unique(on: "podcastID")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("podcastConfig").delete()
        }
    }
}