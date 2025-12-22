import Fluent
import Vapor

struct PodcastsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.grouped("podcasts")
            .grouped(UserAuthenticator())
            .group(AuthPayload.guardMiddleware()) { podcasts in
                podcasts.get(use: getAllPodcasts)

                podcasts.group(":podcastID") { podcastID in
                    podcastID.get(use: getPodcast)

                    // Admin only routes
                    podcastID.group(AdminAuthMiddleware()) { podcastID in
                        podcastID.delete(use: deletePodcast)
                    }
                }

                try podcasts.register(collection: PodcastConfigController())
                try podcasts.register(collection: RSSFeedController())
            }
    }

    private func getAllPodcasts(req: Request) async throws -> [PodcastDTO] {
        let query = try req.query.decode(GetAllPodcastsQueryParameters.self)

        return try await Podcast.query(on: req.db)
            .when(query._config != .none) { $0.with(\.$config) }
            .when(query._includeRSSConfig) { $0.with(\.$rssConfig) }
            .all()
            .map { try PodcastDTO(from: $0, overrideWithConfig: query._config == .override) }
    }

    private func getPodcast(req: Request) async throws -> PodcastDTO {
        guard let id = req.parameters.get("podcastID", as: UUID.self)
        else { throw Errors.invalidIDFormat }

        let query = try req.query.decode(GetPodcastQueryParameters.self)

        let podcast = try await Podcast.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$episodes) { episode in
                if query._episodeConfig != .none {
                    episode.with(\.$config)
                }

                if query._includeEpisodeAudio {
                    episode.with(\.$audioConfig)
                }
            }
            .when(query._config != .none) { $0.with(\.$config) }
            .when(query._includeRSSConfig) { $0.with(\.$rssConfig) }
            .first()
            .unwrap(or: Errors.unknownID)

        req.logger.info("\(query)")

        return try PodcastDTO(
            from: podcast,
            with: podcast.episodes.map {
                try EpisodeDTO(from: $0, overrideWithConfig: query._episodeConfig == .override)
            },
            overrideWithConfig: query._config == .override
        )
    }

    private func deletePodcast(req: Request) async throws -> Response {
        guard let id = req.parameters.get("podcastID", as: UUID.self)
        else { throw Errors.invalidIDFormat }

        let query = Podcast.query(on: req.db)
            .filter(\.$id == id)

        guard try await query.count() > 0
        else { throw Errors.unknownID }

        try await query.delete()

        return Response(status: .noContent)
    }
}

extension PodcastsController {
    enum Errors {
        static var unknownID: Abort { Abort(.badRequest, reason: "Unknown id provided") }
        static var invalidIDFormat: Abort { Abort(.badRequest, reason: "Invalid id format") }
    }
}

// MARK: Query Parameter Models
extension PodcastsController {
    struct GetPodcastQueryParameters: Content {
        var config: ConfigMode?
        var _config: ConfigMode { config ?? .override }

        var includeRSSConfig: Bool?
        var _includeRSSConfig: Bool { includeRSSConfig ?? false }

        var episodeConfig: ConfigMode?
        var _episodeConfig: ConfigMode { episodeConfig ?? .override }

        var includeEpisodeAudio: Bool?
        var _includeEpisodeAudio: Bool { includeEpisodeAudio ?? true }
    }

    struct GetAllPodcastsQueryParameters: Content {
        var config: ConfigMode?
        var _config: ConfigMode { config ?? .override }

        var includeRSSConfig: Bool?
        var _includeRSSConfig: Bool { includeRSSConfig ?? false }
    }
}
