import Vapor

/// Sets up Episodes endpoints.
///
/// `GET /api/episodes/:episodeID`: Retrieves an episode based on a provided id.
struct EpisodesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group("episodes", ":episodeID") { episodeID in
            episodeID.get(use: getEpisode)
        }
    }
    
    /// Returns metadata for the episode with the provided episode id.
    ///
    /// - Returns: `200 Ok` status with a ``EpisodeDTO`` in the body.
    private func getEpisode(_ req: Request) async throws -> EpisodeDTO {
        let id = try req.parameters.require("episodeID", as: UUID.self)
        
        return try await req.episodeDAO
            .read(with: id)
            .unwrap(or: DBError.noItemFound("Episode", with: id))
            .toDTO()
    }
}
