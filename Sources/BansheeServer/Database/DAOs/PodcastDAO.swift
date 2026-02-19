import Fluent
import Vapor

extension Request {
    /// An access object used to read ``Podcast`` information from a database.
    var podcastDAO: PodcastDAO {
        PodcastDAO(db: db)
    }
}

/// The access object used to read ``Podcast`` information from a database.
struct PodcastDAO {
    
    /// The database to read from.
    let db: any Database
    
    /// Creates a podcast including its RSS Feed and Episodes.
    ///
    /// - Parameters:
    ///   - podcast: The ``Podcast`` to create.
    ///   - feed: The ``RSSFeed`` to create.
    ///   - episodes: An array of ``Episode`` to create.
    ///
    /// - Returns: The created ``Podcast`` including its feed, and episodes.
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
    
    /// Reads all podcasts in the database, optionally including their RSSFeeds.
    ///
    /// - Parameters:
    ///   - includingRSS: A `Bool` value that controls whether rss feeds are included in the request / response.
    ///
    /// - Returns: An array of ``Podcast`` including their ``RSSFeed`` when `includingRSS` is `true`.
    func read(includingRSS: Bool = false) async throws -> [Podcast] {
        try await Podcast.query(on: db)
            .when(includingRSS) { $0.with(\.$feed) }
            .all()
    }
    
    /// Reads a podcasts with a provided id in the database, optionally including it's RSSFeeds.
    ///
    /// - Parameters:
    ///   - id: The id of the podcast to fetch.
    ///   - includingRSS: A `Bool` value that controls whether rss feeds are included in the request / response.
    ///
    /// - Returns: An optional ``Podcast`` including it's ``RSSFeed`` when `includingRSS` is `true`. `nil` when no matching value is found.
    func read(with id: UUID, includingRSS: Bool = false) async throws -> Podcast? {
        try await Podcast.query(on: db)
            .filter(\.$id == id)
            .when(includingRSS) { $0.with(\.$feed) }
            .first()
    }
    
    /// Updates the provided podcast onto the database.
    func update(_ podcast: Podcast) async throws {
        try await podcast.save(on: db)
    }
    
    /// Deletes the podcast with the matching id, if one is found.
    func delete(with id: UUID) async throws {
        try await Podcast.query(on: db)
            .filter(\.$id == id)
            .delete()
    }
}
