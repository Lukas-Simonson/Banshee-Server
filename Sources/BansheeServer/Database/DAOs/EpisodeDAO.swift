import Fluent
import Vapor

extension Request {
    var episodeDAO: EpisodeDAO {
        EpisodeDAO(db: db)
    }
}

struct EpisodeDAO {
    let db: any Database
    
    func read(fromPodcastWithID id: UUID) async throws -> [Episode] {
        try await Episode.query(on: db)
            .filter(\.$podcast.$id == id)
            .all()
    }
    
    func read(with id: UUID) async throws -> Episode? {
        try await Episode.query(on: db)
            .filter(\.$id == id)
            .first()
    }
    
    func update(_ episode: Episode) async throws {
        try await episode.update(on: db)
    }
}
