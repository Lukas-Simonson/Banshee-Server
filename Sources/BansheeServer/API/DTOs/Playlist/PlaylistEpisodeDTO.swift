import Vapor

struct PlaylistEpisodeDTO: Content {
    let id: UUID
    let position: Double
    let playlistID: UUID
    let episode: EpisodeDTO
}

extension PlaylistEpisode {
    func toDTO(
        episodeConfigMode: ConfigMode = .override,
        includeEpisodeAudio: Bool = false
    ) throws -> PlaylistEpisodeDTO {
        try PlaylistEpisodeDTO(
            id: requireID(),
            position: position,
            playlistID: $playlist.id,
            episode: episode.toDTO(
                configMode: episodeConfigMode,
                includeAudio: includeEpisodeAudio,
                progress: try? joined(EpisodeProgress.self)
            )
        )
    }
}
