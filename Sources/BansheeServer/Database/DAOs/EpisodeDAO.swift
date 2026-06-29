import Fluent
import FluentSQL
import Vapor

extension Request {
    /// An access object used to read ``Episode`` information from a database.
    var episodeDAO: EpisodeDAO {
        EpisodeDAO(db: db)
    }
}

/// The access object used to read ``Episode`` information from a database.
struct EpisodeDAO {
    
    /// The database to read from.
    let db: any Database
    
    /// Reads episodes from a podcast using the podcasts id.
    ///
    /// - Parameters:
    ///   - id: The id of the podcast to fetch episodes from.
    ///   - userID: The optional id of a user who's progress should be included with the episodes. No progress is included when `userID` is nil.
    ///
    /// - Returns: An array of ``Episode``
    func read(fromPodcastWithID id: UUID, includeProgressForUserWithID userID: UUID? = nil) async throws -> [Episode] {
        try await Episode.query(on: db)
            .filter(\.$podcast.$id == id)
            .when(userID != nil) { query in
                query
                    // TODO: There may be a way to do this operation without a Join, but this way works for now.
                    .join(EpisodeProgress.self, on: \Episode.$id == \EpisodeProgress.$episode.$id)
                    .filter(EpisodeProgress.self, \.$user.$id == userID!)
                    .limit(1)
            }
            .all()
    }
    
    /// Reads an episode with a provided id.
    ///
    /// - Parameters:
    ///   - id: The id of the episode to fetch.
    ///   - userID: The optional id of a user who's progress should be included with the episode. No progress is included when `userID` is nil.
    ///
    /// - Returns: An optional ``Episode``, `nil` when no matching value is found.
    func read(with id: UUID, includeProgressForUserWithID userID: UUID? = nil) async throws -> Episode? {
        if let userID, let sql = db as? any SQLDatabase {
            return try await sql.raw("""
                SELECT * FROM episode
                LEFT JOIN episode_progress
                ON episode_progress.episode_id = episode.id 
                AND episode_progress.user_id = \(bind: userID)
                WHERE episode.id = \(bind: id);
            """).first(decodingFluent: Episode.self)
        }
        
        return try await Episode.find(id, on: db)
    }
    
    /// Reads all episodes with IDs contained in the provided id array.
    ///
    /// - Parameters:
    ///   - ids: The array of ids to fetch with
    ///
    /// - Returns: An array of ``Episode``.
    func readAll(in ids: [UUID], includeDownloads: Bool = false) async throws -> [Episode] {
        try await Episode.query(on: db)
            .filter(\.$id ~~ ids)
            .when(includeDownloads) { query in
                query.with(\.$download)
            }
            .all()
    }
    
    /// Updates the provided episode onto the database.
    func update(_ episode: Episode) async throws {
        try await episode.save(on: db)
    }
}
