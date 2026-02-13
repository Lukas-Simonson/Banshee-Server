import Vapor

/// Sets up the Podcast endpoints
///
/// - `GET /api/podcasts`: Gets all available podcasts.
/// - `GET /api/podcasts/:podcastID`: Get information for a single podcast.
/// - `DELETE /api/podcasts/:podcastID`: Deletes a podcast.
/// - `GET /api/podcasts/:podcastID/episodes`: Gets all episodes in a podcast.
struct PodcastsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.group("podcasts") { podcasts in
            podcasts.get(use: getAllPodcasts)
            
            try podcasts.register(collection: FeedsController())
            
            podcasts.group(":podcastID") { podcastID in
                podcastID.get(use: getPodcast)
                podcastID.get("episodes", use: getEpisodes)
                
                podcastID.group(UserToken.adminGuardMiddleware()) { adminPodcastID in
                    adminPodcastID.delete(use: deletePodcast)
                }
            }
        }
    }
    
    /// Returns metadata for all podcasts tracked by the server.
    ///
    /// - Returns: `200 Ok` status with an Array of ``PodcastDTO`` in the body.
    private func getAllPodcasts(req: Request) async throws -> [PodcastDTO] {
        try await req.podcastDAO
            .read()
            .map { try $0.toDTO() }
    }
    
    /// Returns metadata for the podcast with the provided podcast id.
    ///
    /// - Returns: `200 Ok` status with a ``PodcastDTO`` in the body.
    private func getPodcast(req: Request) async throws -> PodcastDTO {
        let id = try req.parameters.require("podcastID", as: UUID.self)
        
        return try await req.podcastDAO
            .read(with: id)
            .unwrap(or: DBError.noItemFound("Podcast", with: id))
            .toDTO()
    }
    
    /// Returns episode metadata for episodes in the podcast with the provided id.
    ///
    /// - Returns: `200 Ok` status with an Array of ``EpisodeDTO`` in the body.
    private func getEpisodes(req: Request) async throws -> [EpisodeDTO] {
        let id = try req.parameters.require("podcastID", as: UUID.self)
        
        guard try await Podcast.exists(with: id, on: req.db)
        else { throw DBError.noItemFound("Podcast", with: id) }
        
        return try await req.episodeDAO
            .read(fromPodcastWithID: id)
            .map { try $0.toDTO() }
    }
    
    /// Deletes a podcast and its pertaining metadata from the server.
    ///
    /// - Returns: `204 No Content` on a successful delete operation.
    private func deletePodcast(req: Request) async throws -> Response {
        let id = try req.parameters.require("podcastID", as: UUID.self)
        
        try await req.podcastDAO.delete(with: id)
        
        return Response(status: .noContent)
    }
}
