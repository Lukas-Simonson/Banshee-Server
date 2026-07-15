import Fluent
import Vapor

extension Request {
    /// An access object used to read ``RSSFeed`` information from a database.
    var rssFeedDAO: RSSFeedDAO {
        RSSFeedDAO(db: db)
    }
}

/// The access object used to read ``RSSFeed`` information from a database.
struct RSSFeedDAO {
    
    /// The database to read from.
    let db: any Database
    
    /// Reads an ``RSSFeed`` that has a matching url.
    func feed(with url: URI) async throws -> RSSFeed? {
        try await RSSFeed.query(on: db)
            .filter(\.$url == url)
            .first()
    }
    
    func expiredFeeds() async throws -> [RSSFeed] {
        try await RSSFeed.query(on: db)
            .filter(\.$updateInterval != nil)
            .with(\.$podcast) { podcast in
                podcast.with(\.$episodes)
            }
            .all()
            .filter { $0.isExpired } // MARK: Could be done with a fancy query filter, but should be fine for now.
    }
}
