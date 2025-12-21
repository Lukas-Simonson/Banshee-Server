import Fluent
import Vapor

struct RSSFeedController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped("feeds").group(AdminAuthMiddleware()) { feeds in
            feeds.get(use: getAllFeeds)
            feeds.post(use: registerFeed)
        }
    }

    private func registerFeed(req: Request) async throws -> PodcastDTO {
        let feedRequest = try req.content.decode(CreatePodcastFeedRequest.self)

        let rssResponse = try await req.client.get(URI(from: feedRequest.url))
            .content.decode(RSS.self)

        // Save Podcast
        var podcast = rssResponse.channel.toModel()
        try await podcast.save(on: req.db)

        // TODO: See if there is a more efficient way to do this.
        for episode in rssResponse.channel.item {
            let model = episode.toModel()
            try await podcast.$episodes.create(model, on: req.db)
            try await model.$audioConfig.create(episode.enclosure.toModel(), on: req.db)
        }

        try await podcast.$rssConfig.create(RSSConfig(url: feedRequest.url), on: req.db)

        podcast = try await Podcast.query(on: req.db)
            .filter(\.$id == podcast.id!)
            .with(\.$rssConfig)
            .first()
            .unwrap(or: Errors.failedToCreatePodcast)

        return try PodcastDTO(from: podcast, overrideWithConfig: false)
    }

    private func getAllFeeds(req: Request) async throws -> [RSSConfigDTO] {
        try await RSSConfig.query(on: req.db)
            .with(\.$podcast)
            .all()
            .compactMap { try RSSConfigDTO(from: $0) }
    }
}

extension RSSFeedController {
    enum Errors {
        static var failedToCreatePodcast: Abort { Abort(.internalServerError, reason: "Failed to create podcast & rss feed") }
    }
}

// MARK: - Request Objects
extension RSSFeedController {
    struct CreatePodcastFeedRequest: Content {
        let url: URL
    } 
}