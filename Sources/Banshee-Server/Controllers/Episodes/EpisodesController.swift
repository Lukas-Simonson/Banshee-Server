import Fluent
import Vapor

struct EpisodesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.grouped("episodes")
            .grouped(UserAuthenticator())
            .group(AuthPayload.guardMiddleware()) { episodes in
                // NOTE: Will likely be used more for later. Used as a wrapper for now.
                try episodes.register(collection: EpisodeConfigController())
                try episodes.register(collection: EpisodeDownloadController())
                try episodes.register(collection: EpisodeAudioController())

                episodes.get(":episodeID", use: getEpisode)
            }
    }    

    private func getEpisode(req: Request) async throws -> EpisodeDTO {
        guard let id = req.parameters.get("episodeID", as: UUID.self)
        else { throw Errors.invalidIDFormat }

        let episode = try await Episode.query(on: req.db)
            .filter(\.$id == id)
            .first()
            .unwrap(or: Errors.unknownID)

        return try EpisodeDTO(from: episode, overrideWithConfig: false)
    }
}

extension EpisodesController {
    enum Errors {
        static var unknownID: Abort { PodcastsController.Errors.unknownID }
        static var invalidIDFormat: Abort { PodcastsController.Errors.invalidIDFormat }
    }
}
