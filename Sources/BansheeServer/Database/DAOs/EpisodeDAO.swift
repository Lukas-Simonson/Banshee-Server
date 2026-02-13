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
}
