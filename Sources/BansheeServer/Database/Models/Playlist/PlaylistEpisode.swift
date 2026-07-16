import Fluent
import Vapor

final class PlaylistEpisode: Model, @unchecked Sendable {
    
    /// The unique identifier used by the server.
    @ID
    var id: UUID?
    
    /// The order of the item within the playlist.
    @Field(key: "position")
    var position: Double
    
    /// The playlist this episode belongs to.
    @Parent(key: "playlist_id")
    var playlist: Playlist
    
    /// The episode that belongs in the playlist.
    @Parent(key: "episode_id")
    var episode: Episode
    
    init() {}
    
    init(position: Double, episodeID: UUID) {
        self.position = position
        self.$episode.id = episodeID
    }
}

extension PlaylistEpisode {
    static let schema = "playlist_episode"
    
    enum Migration { }
}

extension PlaylistEpisode.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("playlist_episode")
                .id()
                .field("position", .double, .required)
                .field("playlist_id", .uuid, .required, .references("playlist", "id", onDelete: .cascade))
                .field("episode_id", .uuid, .required, .references("episode", "id", onDelete: .cascade))
                .unique(on: "playlist_id", "episode_id")
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema("playlist_episode")
                .delete()
        }
    }
}
