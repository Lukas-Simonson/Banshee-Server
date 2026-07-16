import Vapor

struct PlaylistEpisodeDTO: Content {
    let id: UUID
    let position: Double
    let playlistID: UUID
    let episode: EpisodeDTO
}

extension PlaylistEpisode {
    func toDTO() throws -> PlaylistEpisodeDTO {
        try PlaylistEpisodeDTO(
            id: requireID(),
            position: position,
            playlistID: $playlist.id,
            episode: episode.toDTO(
                configMode: .override,
                includeAudio: false
            )
        )
    }
}
