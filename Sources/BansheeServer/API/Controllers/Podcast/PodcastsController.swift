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
            
            try podcasts.group(":podcastID") { podcastID in
                podcastID.get(use: getPodcast)
                podcastID.get("episodes", use: getEpisodes)
                
                try podcastID.register(collection: PodcastConfigController())
                
                podcastID.group(UserToken.adminGuardMiddleware()) { adminPodcastID in
                    adminPodcastID.delete(use: deletePodcast)
                }
            }
        }
    }
    
    /// Returns metadata for all podcasts tracked by the server.
    ///
    /// - Query Parameters:
    ///   - `config`: Controls how the podcast configs are utilized.
    ///     - Valid: `none`, `include`, `override`
    ///     - Default: `override`
    ///   - `includeRSS`: `Bool` value controlling if RSS Feeds should be included in the response.
    ///     - Default: `false`
    ///
    /// - Returns: `200 Ok` status with an Array of ``PodcastDTO`` in the body.
    private func getAllPodcasts(req: Request) async throws -> [PodcastDTO] {
        try GetAllPodcastsQuery.validate(query: req)
        let query = try req.query.decode(GetAllPodcastsQuery.self)
        
        return try await req.podcastDAO
            .read(includingRSS: query.includeRSS ?? false)
            .map { try $0.toDTO(configMode: query.config ?? .override) }
    }
    
    /// Returns metadata for the podcast with the provided podcast id.
    ///
    /// - Query Parameters:
    ///   - `config`: Controls how the podcasts config is utilized.
    ///     - Valid: `none`, `include`, `override`
    ///     - Default: `override`
    ///   - `includeRSS`: `Bool` value controlling if the RSS Feed should be included in the response.
    ///     - Default: `false`
    ///
    /// - Returns: `200 Ok` status with a ``PodcastDTO`` in the body.
    private func getPodcast(req: Request) async throws -> PodcastDTO {
        let id = try req.parameters.require("podcastID", as: UUID.self)
        
        try GetAllPodcastsQuery.validate(query: req)
        let query = try req.query.decode(GetAllPodcastsQuery.self)
        
        return try await req.podcastDAO
            .read(with: id, includingRSS: query.includeRSS ?? false)
            .unwrap(or: DBError.noItemFound("Podcast", with: id))
            .toDTO(configMode: query.config ?? .override)
    }
    
    /// Returns episode metadata for episodes in the podcast with the provided id.
    ///
    /// - Query Parameters:
    ///   - `config`: Controls how the episode configs are utilized.
    ///     - Valid: `none`, `include`, `override`
    ///     - Default: `override`
    ///   - `includeAudio`: `Bool` Controls if audio information is included for the episodes.
    ///     - Default: `false`
    ///   - `includeProgress`: Controls if the authenticated users progress is included with the response.
    ///     - Default: `false`
    ///
    /// - Returns: `200 Ok` status with an Array of ``EpisodeDTO`` in the body.
    private func getEpisodes(req: Request) async throws -> [EpisodeDTO] {
        let id = try req.parameters.require("podcastID", as: UUID.self)
        
        try GetEpisodesQuery.validate(query: req)
        let query = try req.query.decode(GetEpisodesQuery.self)
        
        guard let auth = req.auth.get(UserToken.self),
              let userID = auth.userID
        else { throw AuthError.invalidAuth }
        
        try await Podcast.require(oneWith: id, existsOn: req.db, or: DBError.noItemFound("Podcast", with: id))
        
        return try await req.episodeDAO
            .read(
                fromPodcastWithID: id,
                includeProgressForUserWithID: query.includeProgress != true ? nil : userID
            )
            .map {
                try $0.toDTO(
                    configMode: query.config ?? .override,
                    includeAudio: query.includeAudio ?? false
                )
            }
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

extension PodcastsController {
    
    struct GetAllPodcastsQuery: Content, Validatable {
        let config: ConfigMode?
        let includeRSS: Bool?
        
        static func validations(_ validations: inout Validations) {
            validations.add("config", as: String.self, is: .in(["none", "include", "override"]), required: false)
            validations.add("includeRSS", as: Bool.self, required: false)
        }
    }
    
    struct GetPodcastQuery: Content, Validatable {
        let config: ConfigMode?
        let includeRSS: Bool?
        
        static func validations(_ validations: inout Validations) {
            validations.add("config", as: String.self, is: .in(["none", "include", "override"]), required: false)
            validations.add("includeRSS", as: Bool.self, required: false)
        }
    }
    
    struct GetEpisodesQuery: Content, Validatable {
        let config: ConfigMode?
        let includeAudio: Bool?
        let includeProgress: Bool?
        
        static func validations(_ validations: inout Validations) {
            validations.add("config", as: String.self, is: .in(["none", "include", "override"]), required: false)
            validations.add("includeAudio", as: Bool.self, required: false)
            validations.add("includeProgress", as: Bool.self, required: false)
        }
    }
}
