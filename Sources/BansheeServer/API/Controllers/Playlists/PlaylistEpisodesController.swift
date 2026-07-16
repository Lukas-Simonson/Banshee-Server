import Vapor

/// Sets up the Playlist Episodes endpoints.
///
/// `GET /api/playlists/:playlistID/episodes`
struct PlaylistEpisodesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group("episodes") { episodes in
            episodes.get(use: getEpisodes)
        }
    }
    
    func getEpisodes(req: Request) async throws -> [PlaylistEpisodeDTO] {
        let id = try req.parameters.require("playlistID", as: UUID.self)
        
        try GetEpisodesQuery.validate(query: req)
        let query = try req.query.decode(GetEpisodesQuery.self)
        
        let userID = try req.auth.require(UserToken.self).requireID()
        
        try await Playlist.require(oneWith: id, existsOn: req.db, or: DBError.noItemFound("Playlist", with: id))
        
        return try await req.playlistEpisodeDAO
            .read(
                fromPlaylistWithID: id,
                includeProgressForUserWithID: query.includeProgress != true ? nil : userID
            )
            .map {
                try $0.toDTO(
                    episodeConfigMode: query.config ?? .override,
                    includeEpisodeAudio: query.includeAudio ?? false
                )
            }
    }
}

extension PlaylistEpisodesController {
    typealias GetEpisodesQuery = PodcastsController.GetEpisodesQuery
}
