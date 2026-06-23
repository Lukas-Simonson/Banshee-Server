import Fluent
import Vapor

/// Playlist Metadata
final class Playlist: Model, @unchecked Sendable {
    
    /// The unique identifier used by the server.
    @ID
    var id: UUID?
    
    /// The title of the playlist.
    @Field(key: "title")
    var title: String
    
    /// The cover art image to use for the playlist.
    @OptionalField(key: "image_url")
    var imageURL: URI?
    
    /// An optional description of the playlist.
    @OptionalField(key: "description")
    var description: String?
    
    /// Whether or not this playlist is accessible to others on the server.
    @Field(key: "is_public")
    var isPublic: Bool
    
    init() {}
    
    init(title: String, imageURL: URI? = nil, description: String, isPublic: Bool) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.description = description
        self.isPublic = isPublic
    }
}

extension Playlist {
    static let schema = "playlist"
    
    enum Migration {}
}

extension Playlist.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("playlist")
                .id()
                .field("title", .string, .required)
                .field("image_url", .string)
                .field("description", .string)
                .field("is_public", .bool)
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("playlist")
                .delete()
        }
    }
}
