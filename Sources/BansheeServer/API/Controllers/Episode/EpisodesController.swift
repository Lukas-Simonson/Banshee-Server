import Vapor

/// Sets up Episodes endpoints.
///
/// `GET /api/episodes/:episodeID`: Retrieves an episode based on a provided id.
struct EpisodesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.group("episodes", ":episodeID") { episodeID in
            episodeID.get(use: getEpisode)
            
            try episodeID.register(collection: EpisodeConfigController())
            try episodeID.register(collection: EpisodeProgressController())
            try episodeID.register(collection: EpisodeAudioController())
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
}
