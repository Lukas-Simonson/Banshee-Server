import Fluent
import Vapor

extension Request {
    /// An access object used for ``PlaylistEpisode`` information in a database.
    var playlistEpisodeDAO: PlaylistEpisodeDAO {
        PlaylistEpisodeDAO(db: db)
    }
}

struct PlaylistEpisodeDAO {
    /// The database to read from.
    let db: any Database
    
    func read(
        fromPlaylistWithID id: UUID,
        includeProgressForUserWithID userID: UUID? = nil,
    ) async throws -> [PlaylistEpisode] {
        try await PlaylistEpisode.query(on: db)
            .filter(\.$playlist.$id == id)
            .with(\.$episode)
            .sort(\.$position)
            .let(userID) { id, query in
                query.join(
                    EpisodeProgress.self,
                    on: \PlaylistEpisode.$episode.$id == \EpisodeProgress.$episode.$id && \EpisodeProgress.$user.$id == id,
                    method: .left
                )
            }
            .all()
    }
}
