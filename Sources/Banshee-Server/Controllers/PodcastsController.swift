import Vapor

struct PodcastsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let podcasts = routes.grouped("podcasts").grouped(UserAuthenticator())

        podcasts.group("feeds") { feeds in

            // Admin Only Endpoints
            feeds.group(AdminAuthMiddleware()) { feeds in
                feeds.post(use: registerFeed)
            }
        }
    }

    private func registerFeed(req: Request) async throws -> Podcast {
        let feedRequest = try req.content.decode(CreatePodcastFeedRequest.self)

        let rssResponse = try await req.client.get(URI(from: feedRequest.url))
            .content.decode(RSS.self)

        // Save Podcast
        let podcast = rssResponse.channel.toModel(rssFeedURL: feedRequest.url)
        try await podcast.save(on: req.db)
        try await podcast.$episodes.create(rssResponse.channel.item.map { $0.toModel() }, on: req.db)

        return podcast
    }
}

extension Podcast: Content {}

extension PodcastsController {
    enum Errors {
        
    }
}

// MARK: - Request Objects
extension PodcastsController {
    struct CreatePodcastFeedRequest: Content {
        let url: URL
    } 
}
