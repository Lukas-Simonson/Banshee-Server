import Fluent
import Vapor

extension Request {
    var episodeDAO: EpisodeDAO {
        EpisodeDAO(db: db)
    }
}

struct EpisodeDAO {
    let db: any Database
    
    func read(fromPodcastWithID id: UUID, includeProgressForUserWithID userID: UUID? = nil) async throws -> [Episode] {
        try await Episode.query(on: db)
            .filter(\.$podcast.$id == id)
            .when(userID != nil) { query in
                query
                    .join(EpisodeProgress.self, on: \Episode.$id == \EpisodeProgress.$episode.$id)
                    .filter(EpisodeProgress.self, \.$user.$id == userID!)
                    .limit(1)
            }
            .all()
    }
    
    func read(with id: UUID, includeProgressForUserWithID userID: UUID? = nil) async throws -> Episode? {
        try await Episode.query(on: db)
            .filter(\.$id == id)
            .when(userID != nil) { query in
                query
                    .join(EpisodeProgress.self, on: \Episode.$id == \EpisodeProgress.$episode.$id)
                    .filter(EpisodeProgress.self, \.$user.$id == userID!)
                    .limit(1)
            }
            .first()
    }
    
    func update(_ episode: Episode) async throws {
        try await episode.save(on: db)
    }
}
