import Fluent
import Vapor

final class AudioConfig: Model, @unchecked Sendable {
    @ID
    var id: UUID?

    @Field(key: "remoteURL")
    var remoteURL: URL?

    @Field(key: "localURL")
    var localURL: URL?

    @Field(key: "length")
    var length: Int64?

    @Field(key: "type")
    var type: String?

    @Parent(key: "episodeID")
    var episode: Episode
}

// MARK: Model Conformance
extension AudioConfig {
    static let schema = "audioConfig"

    enum Migration { }
}

extension AudioConfig.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("audioConfig")
                .id()
                .field("remoteURL", .string)
                .field("localURL", .string)
                .field("length", .int64)
                .field("type", .string)
                .field("episodeID", .uuid, .required, .references("episode", "id", onDelete: .cascade))
                .unique(on: "episodeID")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("audioConfig").delete()
        }
    }
}