import Fluent
import Vapor

struct PodcastConfigController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped(":podcastID", "config").group(AdminAuthMiddleware()) { config in
            config.post(use: upsertConfig)
        }
    }

    func upsertConfig(req: Request) async throws -> PodcastDTO {
        guard let id = req.parameters.get("podcastID", as: UUID.self)
        else { throw Errors.invalidIDFormat }
        
        let config = try req.content.decode(PodcastConfigDTO.self)
        let query = Podcast.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$config)

        var podcast = try await query.first().unwrap(or: Errors.unknownID)

        if let configID = podcast.config?.id {
            try await config.toModel(with: configID).update(on: req.db)
        } else {
            try await podcast.$config.create(config.toModel(with: nil), on: req.db)
        }

        podcast = try await query.first().unwrap(or: Errors.unknownID)

        return try PodcastDTO(from: podcast, overrideWithConfig: true)
    }
}

extension PodcastConfigController {
    enum Errors {
        static var unknownID: Abort { PodcastsController.Errors.unknownID }
        static var invalidIDFormat: Abort { PodcastsController.Errors.invalidIDFormat }
    }
}