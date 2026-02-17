import Fluent
import Vapor

extension Request {
    var episodeProgressDAO: EpisodeProgressDAO {
        EpisodeProgressDAO(db: db)
    }
}

struct EpisodeProgressDAO {
    let db: any Database
    
    func read(fromEpisodeWithID episodeID: UUID, fromUserWithID userID: UUID) async throws -> EpisodeProgress? {
        try await EpisodeProgress.query(on: db)
            .filter(\.$episode.$id == episodeID)
            .filter(\.$user.$id == userID)
            .first()
    }
    
    func update(_ progress: EpisodeProgress, forEpisodeWithID episodeID: UUID, forUserWithID userID: UUID) async throws {
        progress.$episode.id = episodeID
        progress.$user.id = userID
        
        try await progress.save(on: db)
    }
    
    func deleteWhere(episodeID: UUID, userID: UUID) async throws {
        try await EpisodeProgress.query(on: db)
            .filter(\.$episode.$id == episodeID)
            .filter(\.$user.$id == userID)
            .delete()
    }
}
