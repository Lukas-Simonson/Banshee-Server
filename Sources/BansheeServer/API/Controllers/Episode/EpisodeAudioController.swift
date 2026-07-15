import Vapor

/// Sets up the episode audio endpoints
///
/// `GET /api/episodes/:episodeID/audio`
struct EpisodeAudioController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group("audio") { audio in
            audio.get(use: streamEpisodeAudio)
        }
    }
    
    /// Attempts to stream audio from the server, falling back to a redirect to the episodes source.
    ///
    /// - Returns:
    ///   - `200 Ok` status with the file stream.
    ///   - `307 Temporary` status with a redirect to the episode source.
    private func streamEpisodeAudio(req: Request) async throws -> Response {
        let id = try req.parameters.require("episodeID", as: UUID.self)
        
        let episode = try await req.episodeDAO
            .read(with: id)
            .unwrap(or: DBError.noItemFound("Episode", with: id))
        
        if let remote = episode.audio.remoteURL, episode.audio.localURL == nil {
            // No local audio, redirect to origin server.
            return req.redirect(to: remote.string, redirectType: .temporary)
        }
        
        guard let localURL = episode.audio.localURL
        else { throw FileError.noAudioFiles }
        
        return try await req.fileio.asyncStreamFile(at: localURL.relativePath)
    }
}
