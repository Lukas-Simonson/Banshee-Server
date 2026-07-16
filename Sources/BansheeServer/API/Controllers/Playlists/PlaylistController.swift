import Vapor

/// Sets up playlist endpoints
///
/// `GET /api/playlists`: Lists the users available playlists.
/// `POST /api/playlists`: Creates a new playlist
struct PlaylistController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.group("playlists") { playlists in
            playlists.get(use: getPlaylists)
            playlists.post(use: createPlaylist)
            
            try playlists.group(":playlistID") { playlistID in
                try playlistID.register(collection: PlaylistEpisodesController())
            }
        }
    }
    
    /// Lists all playlists available to the requesting user.
    func getPlaylists(req: Request) async throws -> Response {
        let token = try req.auth.require(UserToken.self)
        
        guard let userID = token.userID
        else { throw AuthError.invalidAuth }
        
        return try await req.playlistDAO
            .readAll(for: userID)
            .map { try $0.toDTO() }
            .encodeResponse(for: req)
    }
    
    func createPlaylist(req: Request) async throws -> Response {
        try PlaylistCreationRequest.validate(content: req)
        let creationRequest = try req.content.decode(PlaylistCreationRequest.self)
        
        return try await req.playlistDAO.create(
            title: creationRequest.title,
            imageURL: creationRequest.imageURL,
            description: creationRequest.description,
            isPublic: creationRequest.isPublic,
            creatorID: req.auth.require(UserToken.self).requireID(),
            episodeIDs: creationRequest.episodeIDs
        )
        .toDTO()
        .encodeResponse(status: .created, for: req)
    }
}

extension PlaylistController {
    
    /// A request to create a playlist.
    struct PlaylistCreationRequest: Content, Validatable {
        
        /// The title of the playlist.
        let title: String
        
        /// The cover art image url for the playlist.
        let imageURL: URL?
        
        /// A description of the playlist.
        let description: String?
        
        /// If this playlist should be shared with other users.
        let isPublic: Bool
        
        /// An initial seed of episodes to include in the playlist.
        let episodeIDs: [UUID]?
        
        static func validations(_ validations: inout Validations) {
            validations.add("title", as: String.self, is: !.empty)
            validations.add("imageURL", as: String.self, is: .url, required: false)
        }
    }
}
