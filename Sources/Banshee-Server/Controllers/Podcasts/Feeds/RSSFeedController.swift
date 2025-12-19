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
        let podcast = rssResponse.channel.toModel(rssFeedURL: feedRequest.url)
        try await podcast.save(on: req.db)
        try await podcast.$episodes.create(rssResponse.channel.item.map { $0.toModel() }, on: req.db)

        return try PodcastDTO(from: podcast, overrideWithConfig: false)
    }

    private func getAllFeeds(req: Request) async throws -> [FeedResponse] {
        let podcasts = try await Podcast.query(on: req.db)
            .filter(\.$rssFeedURL != nil)
            // Request only required fields
            .field(\.$id).field(\.$rssFeedURL).field(\.$title)
            .all()

        return try podcasts.map { podcast in
            FeedResponse(
                id: try podcast.requireID(), 
                url: podcast.rssFeedURL!, 
                title: podcast.title
            )
        }
    }
}

// MARK: - Request Objects
extension RSSFeedController {
    struct CreatePodcastFeedRequest: Content {
        let url: URL
    } 
}

// MARK: - Response Objects
extension RSSFeedController {
    struct FeedResponse: Content {
        let id: UUID
        let url: URL
        let title: String
    }
}