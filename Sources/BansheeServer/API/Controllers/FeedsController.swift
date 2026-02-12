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

//private func registerFeed(req: Request) async throws -> PodcastDTO {
//    let feedRequest = try req.content.decode(CreatePodcastFeedRequest.self)
//
//    let rssResponse = try await req.client.get(URI(from: feedRequest.url))
//        .content.decode(RSS.self)
//
//    // Save Podcast
//    var podcast = rssResponse.channel.toModel()
//    try await podcast.save(on: req.db)
//
//    // TODO: See if there is a more efficient way to do this.
//    for episode in rssResponse.channel.item {
//        let model = episode.toModel()
//        try await podcast.$episodes.create(model, on: req.db)
//        try await model.$audioConfig.create(episode.enclosure.toModel(), on: req.db)
//    }
//
//    try await podcast.$rssConfig.create(RSSConfig(url: feedRequest.url), on: req.db)
//
//    podcast = try await Podcast.query(on: req.db)
//        .filter(\.$id == podcast.id!)
//        .with(\.$rssConfig)
//        .first()
//        .unwrap(or: Errors.failedToCreatePodcast)
//
//    return try PodcastDTO(from: podcast, overrideWithConfig: false)
//}

//private func registerFeed(req: Request) async throws -> PodcastDTO {
//    let feedRequest = try req.content.decode(CreatePodcastFeedRequest.self)
//
//    let rssResponse = try await req.client.get(URI(from: feedRequest.url))
//        .content.decode(RSS.self)
//
//    // Save Podcast
//    var podcast = rssResponse.channel.toModel()
//    try await podcast.save(on: req.db)
//
//    // TODO: See if there is a more efficient way to do this.
//    for episode in rssResponse.channel.item {
//        let model = episode.toModel()
//        try await podcast.$episodes.create(model, on: req.db)
//        try await model.$audioConfig.create(episode.enclosure.toModel(), on: req.db)
//    }
//
//    try await podcast.$rssConfig.create(RSSConfig(url: feedRequest.url), on: req.db)
//
//    podcast = try await Podcast.query(on: req.db)
//        .filter(\.$id == podcast.id!)
//        .with(\.$rssConfig)
//        .first()
//        .unwrap(or: Errors.failedToCreatePodcast)
//
//    return try PodcastDTO(from: podcast, overrideWithConfig: false)
//}
