import Fluent
import Vapor

struct PodcastsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.grouped("podcasts").group(UserAuthenticator()) { podcasts in
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
            .all()
            .map { try PodcastDTO(from: $0, overrideWithConfig: query._config == .override) }
    }

    private func getPodcast(req: Request) async throws -> PodcastDTO {
        guard let id = req.parameters.get("podcastID", as: UUID.self)
        else { throw Errors.invalidIDFormat }

        let query = try req.query.decode(GetPodcastQueryParameters.self)

        let podcast = try await Podcast.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$episodes)
            .when(query._config != .none, then: { $0.with(\.$config) })
            .first()
            .unwrap(or: Errors.unknownID)
        
        return try PodcastDTO(
            from: podcast, 
            with: podcast.episodes.map { try EpisodeDTO(from: $0, podcastID: podcast.requireID()) },
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
        static var unknownID: Abort { Abort(.badRequest, reason: "Unknown podcast id provided") }
        static var invalidIDFormat: Abort { Abort(.badRequest, reason: "Invalid podcast id format") }
    }
}

// MARK: Query Parameter Models
extension PodcastsController {
    struct GetPodcastQueryParameters: Content {
        var config: ConfigMode?
        var _config: ConfigMode { config ?? .override }
    }

    struct GetAllPodcastsQueryParameters: Content {
        var config: ConfigMode?
        var _config: ConfigMode { config ?? .override }
    }
}
