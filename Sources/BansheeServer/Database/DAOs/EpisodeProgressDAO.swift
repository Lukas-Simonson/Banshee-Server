import Fluent
import Vapor

extension Request {
    /// An access object used to read ``EpisodeProgress`` information from a database.
    var episodeProgressDAO: EpisodeProgressDAO {
        EpisodeProgressDAO(db: db)
    }
}

/// The access object used to read ``EpisodeProgress`` information from a database.
struct EpisodeProgressDAO {
    
    /// The database to read from.
    let db: any Database
    
    /// Reads the progress on an episode with a provided id, for a user with a provided id.
    ///
    /// - Parameters:
    ///   - episodeID: The id of the episode to fetch progress for.
    ///   - userID: The id of the user to fetch progress for.
    ///
    /// - Returns: An optional ``EpisodeProgress``, `nil` when no matching progress can be found.
    func read(fromEpisodeWithID episodeID: UUID, fromUserWithID userID: UUID) async throws -> EpisodeProgress? {
        try await EpisodeProgress.query(on: db)
            .filter(\.$episode.$id == episodeID)
            .filter(\.$user.$id == userID)
            .first()
    }
    
    /// Updates the provided progress, mapping its parent episode and user to match the provided ids.
    ///
    /// - Parameters:
    ///  - progress: The ``EpisodeProgress`` to update in the database.
    ///  - episodeID: The id of the episode this progress is made for.
    ///  - userID: The id of the user this progress is made for.
    func update(_ progress: EpisodeProgress, forEpisodeWithID episodeID: UUID, forUserWithID userID: UUID) async throws {
        progress.$episode.id = episodeID
        progress.$user.id = userID
        
        try await progress.save(on: db)
    }
    
    /// Deletes the progress for an episode and user id pair.
    func deleteWhere(episodeID: UUID, userID: UUID) async throws {
        try await EpisodeProgress.query(on: db)
            .filter(\.$episode.$id == episodeID)
            .filter(\.$user.$id == userID)
            .delete()
    }
}
