import Fluent
import Vapor

extension Request {
    /// An access object used to read ``Podcast`` information from a database.
    var playlistDAO: PlaylistDAO {
        PlaylistDAO(db: db)
    }
}

/// The access object used to read ``Playlist`` information from a database.
struct PlaylistDAO {
    
    /// The database to read from.
    let db: any Database
    
    @discardableResult
    func create(
        title: String,
        imageURL: URL?,
        description: String?,
        isPublic: Bool,
        creatorID: UUID,
        episodeIDs: [UUID]?
    ) async throws -> Playlist {
        let playlist = Playlist(title: title, imageURL: imageURL, description: description, isPublic: isPublic, creatorID: creatorID)
        
        try await db.transaction { db in
            try await playlist.create(on: db)
            
            if let episodeIDs {
                try await playlist.$episodes.create(
                    episodeIDs.enumerated().map { PlaylistEpisode(position: Double($0.offset), episodeID: $0.element) },
                    on: db
                )
            }
        }
        
        return try await Playlist.query(on: db)
            .filter(\.$id == playlist.requireID())
            .with(\.$episodes) { playlistEpisode in
                playlistEpisode
                    .with(\.$episode)
            }
            .limit(1)
            .first()
            .unwrap(or: DBError.noItemFound("Playlist", with: "id: \(playlist.id!)"))
    }
    
    func readAll(for userID: UUID) async throws -> [Playlist] {
        try await Playlist.query(on: db)
            .group(.or) { query in
                query.filter(\.$creator.$id == userID).filter(\.$isPublic == true)
            }
            .all()
    }
}
