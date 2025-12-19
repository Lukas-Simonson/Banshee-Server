import Fluent
import Vapor

struct PodcastsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.grouped("podcasts").group(UserAuthenticator()) { podcasts in
            podcasts.get(use: getAllPodcasts)
            podcasts.get(":podcastID", use: getPodcast)
            
            try podcasts.register(collection: RSSFeedController())
        }
    }

    private func getAllPodcasts(req: Request) async throws -> [PodcastDTO] {
        try await Podcast.query(on: req.db)
            .all()
            .map { try PodcastDTO(from: $0) }
    }

    private func getPodcast(req: Request) async throws -> PodcastDTO {
        guard let id = req.parameters.get("podcastID", as: UUID.self)
        else { throw Errors.invalidIDFormat }

        let podcast = try await Podcast.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$episodes)
            .first()
            .unwrap(or: Errors.unknownID)
        
        return try PodcastDTO(
            from: podcast, 
            with: podcast.episodes.map { try EpisodeDTO(from: $0, podcastID: podcast.requireID()) }
        )
    }
}

extension Podcast: Content {}

extension PodcastsController {
    enum Errors {
        static var unknownID: Abort { Abort(.badRequest, reason: "Unknown podcast id provided") }
        static var invalidIDFormat: Abort { Abort(.badRequest, reason: "Invalid podcast id format") }
    }
}
