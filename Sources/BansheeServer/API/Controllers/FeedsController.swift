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
        
        // Check if feed exists
        if try await req.rssFeedDAO.feed(with: feedRequest.url) != nil {
            throw FeedError.duplicateFeed
        }
        
        let rss = try await req.client.get(feedRequest.url)
            .content
            .decode(RSS.self)
        
        let feed = RSSFeed(url: feedRequest.url)
        let podcast = rss.channel.toModel()
        let episodes = rss.channel.item.map { $0.toModel() }
  
        return try await req.podcastDAO
            .create(podcast, from: feed, with: episodes)
            .toDTO()
            .encodeResponse(status: .created, for: req)
    }
}

extension FeedsController {
    
    /// Request body intended for registering an RSS feed.
    struct AddFeedRequest: Content {
        /// The URL of the RSS Feed.
        let url: URI
    }
    
    enum FeedError {
        static var duplicateFeed: Abort { Abort(.badRequest, reason: "An RSS feed from this URL has already been created.") }
    }
}
