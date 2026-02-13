import Fluent
import Vapor

extension Request {
    var podcastDAO: PodcastDAO {
        PodcastDAO(db: db)
    }
}

struct PodcastDAO {
    let db: any Database
    
    @discardableResult
    func create(_ podcast: Podcast, from feed: RSSFeed, with episodes: [Episode]) async throws -> Podcast {
        do {
            try await db.transaction { db in
                try await podcast.create(on: db)
                try await podcast.$feed.create(feed, on: db)
                try await podcast.$episodes.create(episodes, on: db)
            }
        } catch let error as any DatabaseError where error.isConstraintFailure {
            throw DBError.duplicateRow(of: "RSS Feed")
        }
        
        return podcast
    }
    
    func read() async throws -> [Podcast] {
        try await Podcast.query(on: db)
            .all()
    }
    
    func read(with id: UUID) async throws -> Podcast? {
        try await Podcast.query(on: db)
            .filter(\.$id == id)
            .first()
    }
    
    func delete(with id: UUID) async throws {
        try await Podcast.query(on: db)
            .filter(\.$id == id)
            .delete()
    }
}
