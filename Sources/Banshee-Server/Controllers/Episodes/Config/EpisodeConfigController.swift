import Fluent
import Vapor

struct EpisodeConfigController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped(":episodeID", "config").group(AdminAuthMiddleware()) { config in
            config.post(use: upsertConfig)
        }
    }

    private func upsertConfig(req: Request) async throws -> EpisodeDTO {
        guard let id = req.parameters.get("episodeID", as: UUID.self)
        else { throw Errors.invalidIDFormat }

        let config = try req.content.decode(EpisodeConfigDTO.self)
        let query = Episode.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$config)
        
        var episode = try await query.first().unwrap(or: Errors.unknownID)
        // var podcast = try await query.first().unwrap(or: Errors.unknownID)

        if let configID = episode.config?.id {
            try await config.toModel(with: configID).update(on: req.db)
        } else {
            try await episode.$config.create(config.toModel(with: nil), on: req.db)
        }

        episode = try await query.first().unwrap(or: Errors.unknownID)

        return try EpisodeDTO(from: episode, overrideWithConfig: true)
    }
}

extension EpisodeConfigController {
    enum Errors {
        static var unknownID: Abort { PodcastsController.Errors.unknownID }
        static var invalidIDFormat: Abort { PodcastsController.Errors.invalidIDFormat }
    }
}