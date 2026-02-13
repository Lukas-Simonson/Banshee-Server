import Vapor

/// Sets up the podcast config endpoints
///
/// `PUT /api/podcasts/:podcastID/config`
struct PodcastConfigController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped("config").group(UserToken.adminGuardMiddleware()) { config in
            config.put(use: updateConfig)
        }
    }
    
    private func updateConfig(req: Request) async throws -> Response {
        let id = try req.parameters.require("podcastID", as: UUID.self)
        
        try PodcastConfigDTO.validate(content: req)
        let config = try req.content.decode(PodcastConfigDTO.self)
        
        guard let podcast = try await req.podcastDAO.read(with: id)
        else { throw DBError.noItemFound("Podcast", with: id) }
        
        podcast.config = config.toModel()
        try await req.podcastDAO.update(podcast)
        
        return try await  podcast
            .toDTO(configMode: .override)
            .encodeResponse(status: .accepted, for: req)
    }
}
