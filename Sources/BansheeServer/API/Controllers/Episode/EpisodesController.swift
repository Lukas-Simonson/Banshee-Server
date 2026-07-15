import Vapor

/// Sets up Episodes endpoints.
///
/// `GET /api/episodes/:episodeID`: Retrieves an episode based on a provided id.
struct EpisodesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.group("episodes") { episodes in
            try episodes.group(":episodeID") { episodeID in
                episodeID.get(use: getEpisode)
                
                try episodeID.register(collection: EpisodeConfigController())
                try episodeID.register(collection: EpisodeProgressController())
            }
            
            episodes.grouped("configs").group(UserToken.adminGuardMiddleware()) { configs in
                configs.put(use: bulkUpdateConfig)
            }
        }
    }
    
    /// Returns metadata for the episode with the provided episode id.
    ///
    /// - Query Parameters: ``GetEpisodeQuery``
    ///
    /// - Returns: `200 Ok` status with a ``EpisodeDTO`` in the body.
    private func getEpisode(_ req: Request) async throws -> EpisodeDTO {
        let id = try req.parameters.require("episodeID", as: UUID.self)
        
        try GetEpisodeQuery.validate(query: req)
        let query = try req.query.decode(GetEpisodeQuery.self)
        
        guard let auth = req.auth.get(UserToken.self),
              let userID = auth.userID
        else { throw AuthError.invalidAuth }
        
        return try await req.episodeDAO
            .read(
                with: id,
                includeProgressForUserWithID: query.includeProgress != true ? nil : userID
            )
            .unwrap(or: DBError.noItemFound("Episode", with: id))
            .toDTO(
                configMode: query.config ?? .override,
                includeAudio: query.includeAudio ?? false,
            )
    }
    
    /// Modifies the server's ``EpisodeConfig`` for all provided in the request body.
    ///
    /// - Body: Array of ``EpisodeConfigDTO``
    ///
    /// > Note: If a ``BulkEpisodeConfigRequest`` property is explicitly set to null
    /// > it will remove the value of all the related configs. Omitting a value altogether
    /// > simply changes nothing about the configs.
    ///
    /// - Returns: `202 Accepted` status with all the ``EpisodeDTO``s overridden with their configs in the body.
    private func bulkUpdateConfig(_ req: Request) async throws -> Response {
        try BulkEpisodeConfigRequest.validate(content: req)
        let updateRequest = try req.content.decode(BulkEpisodeConfigRequest.self)
        
        guard !updateRequest.$season.isOmitted || !updateRequest.$imageURL.isOmitted
        else { throw BulkUpdateError.noUpdatesProvided }
        
        let episodes = try await req.episodeDAO.readAll(in: updateRequest.ids)
        
        // MARK: This implementation iterates over the same array 3 different times.
        // Realistically this is fine, but noting in case of performance issues on this endpoint.
        
        for episode in episodes {
            if !updateRequest.$season.isOmitted {
                episode.season = updateRequest.season
            }
            
            if !updateRequest.$imageURL.isOmitted {
                episode.config.imageURL = updateRequest.imageURL
            }
        }
        
        try await req.episodeDAO.update(episodes)
        
        return try await episodes
            .map { try $0.toDTO(configMode: .override, includeAudio: false) }
            .encodeResponse(status: .accepted, for: req)
    }
}

extension EpisodesController {
    
    /// The query parameters for the get episode with id endpoint.
    struct GetEpisodeQuery: Content, Validatable {
        
        /// Controls how the episode's config is utilized.
        /// - Valid: `none`, `include`, `override`
        /// - Default: `override`
        let config: ConfigMode?
        
        /// Controls if audio information is included with the response.
        /// - Default: `false`
        let includeAudio: Bool?
        
        /// Controls if the authenticated users progress is included with the response.
        /// - Default: `false`
        let includeProgress: Bool?
        
        static func validations(_ validations: inout Validations) {
            validations.add("config", as: String.self, is: .in(["none", "include", "override"]), required: false)
            validations.add("includeAudio", as: Bool.self, required: false)
            validations.add("includeProgress", as: Bool.self, required: false)
        }
    }
    
    /// The request for a bulk episode config update.
    struct BulkEpisodeConfigRequest: Content, Validatable {
        
        /// The ids of all the episodes that should be updated with these changes.
        let ids: [UUID]
        
        /// The url of an image to use for these episodes cover arts.
        @Nullable var imageURL: URL?
        
        /// The season to set for all of the episodes.
        @Nullable var season: String?
        
        static func validations(_ validations: inout Validations) {
            validations.add("ids", as: [String].self, is: !.empty, required: true)
            validations.add("imageURL", as: String.self, is: .url)
        }
    }
    
    enum BulkUpdateError {
        static var noUpdatesProvided: Abort { Abort(.badRequest, reason: "No updates provided, imageURL or season must be provided.") }
    }
}
