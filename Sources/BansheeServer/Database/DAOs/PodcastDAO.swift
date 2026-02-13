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
    
    func read(includingRSS: Bool = false) async throws -> [Podcast] {
        try await Podcast.query(on: db)
            .when(includingRSS) { $0.with(\.$feed) }
            .all()
    }
    
    func read(with id: UUID, includingRSS: Bool = false) async throws -> Podcast? {
        try await Podcast.query(on: db)
            .filter(\.$id == id)
            .when(includingRSS) { $0.with(\.$feed) }
            .first()
    }
    
    func update(_ podcast: Podcast) async throws {
        try await podcast.update(on: db)
    }
    
    func delete(with id: UUID) async throws {
        try await Podcast.query(on: db)
            .filter(\.$id == id)
            .delete()
    }
}
