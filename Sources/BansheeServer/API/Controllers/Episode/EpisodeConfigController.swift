import Vapor

/// Sets up the episode config endpoints
///
/// `PUT /api/episodes/:episodeID/config`
struct EpisodeConfigController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped("config").group(UserToken.adminGuardMiddleware()) { config in
            config.put(use: updateConfig)
        }
    }
    
    private func updateConfig(req: Request) async throws -> Response {
        let id = try req.parameters.require("episodeID", as: UUID.self)
        
        try EpisodeConfigDTO.validate(content: req)
        let config = try req.content.decode(EpisodeConfigDTO.self)
        
        guard let episode = try await req.episodeDAO.read(with: id)
        else { throw DBError.noItemFound("Episode", with: id) }
        
        episode.config = config.toModel()
        try await req.episodeDAO.update(episode)
        
        return try await episode
            .toDTO(configMode: .override, includeAudio: false)
            .encodeResponse(status: .accepted, for: req)
    }
}
