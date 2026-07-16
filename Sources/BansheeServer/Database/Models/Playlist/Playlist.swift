import Fluent
import FluentSQLiteDriver
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
    
    @OptionalParent(key: "creator_id")
    var creator: User?
    
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
                .field("creator_id", .uuid, .references("user", "id", onDelete: .setNull))
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("playlist")
                .delete()
        }
    }
    
    struct DeletePrivatePlaylistTrigger: AsyncMigration {
        func prepare(on database: any Database) async throws {
            guard let db = database as? any SQLDatabase
            else { throw DBError.UnsupportedDatabase() }
            
            switch db {
                case is any SQLiteDatabase:
                    try await db.raw("""
                    CREATE TRIGGER delete_private_playlist_when_creator_removed
                    AFTER UPDATE OF creator_id
                    ON playlist
                    FOR EACH ROW
                    WHEN
                        NEW.creator_id IS NULL
                        AND OLD.creator_id IS NOT NULL
                        AND NEW.is_public = 0
                    BEGIN
                        DELETE FROM playlist
                        WHERE id = NEW.id;
                    END;
                    """).run()
                default:
                    throw DBError.UnsupportedDatabase()
            }
        }
        
        func revert(on database: any Database) async throws {
            guard let db = database as? any SQLDatabase
            else { throw DBError.UnsupportedDatabase() }
            
            switch db {
                case is any SQLiteDatabase:
                    try await db.raw("""
                    DROP TRIGGER delete_private_playlist_when_creator_removed;
                    """).run()
                default:
                    throw DBError.UnsupportedDatabase()
            }
        }
    }
}
