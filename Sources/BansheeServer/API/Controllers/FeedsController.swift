import Vapor

/// Sets up RSS Feed Endpoints.
///
/// - `POST /api/podcasts/feeds`: Begins processing a collection of RSS feeds.
struct FeedsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped("feeds").group(UserToken.adminGuardMiddleware()) { feeds in
            feeds.post(use: register)
        }
    }
    
    /// Registers a podcasts RSS feed, downloading its metadata.
    ///
    /// - Returns: `201 Created` status with a ``PodcastDTO`` body.
    private func register(req: Request) async throws -> Response {
        let feedRequest = try req.content.decode(AddFeedRequest.self)
        
        let rss = try await req.client.get(feedRequest.url)
            .content
            .decode(RSS.self)
        
        let podcast = rss.channel.toModel()
        let episodes = rss.channel.item.map { $0.toModel() }
        
        try await req.db.transaction { db in
            try await podcast.save(on: db)
            try await podcast.$episodes.create(episodes, on: db)
        }
        
        return try Response(
            status: .created,
            content: podcast.toDTO(),
            encoder: req.contentEncoder
        )
    }
}

extension FeedsController {
    
    /// Request body intended for registering an RSS feed.
    struct AddFeedRequest: Content {
        /// The URL of the RSS Feed.
        let url: URI
    }
}
