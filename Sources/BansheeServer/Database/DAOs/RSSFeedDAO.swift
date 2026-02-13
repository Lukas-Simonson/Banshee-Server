import Fluent
import Vapor

extension Request {
    var rssFeedDAO: RSSFeedDAO {
        RSSFeedDAO(db: db)
    }
}

struct RSSFeedDAO {
    let db: any Database
    
    func feed(with url: URI) async throws -> RSSFeed? {
        try await RSSFeed.query(on: db)
            .filter(\.$url == url)
            .first()
    }
}
