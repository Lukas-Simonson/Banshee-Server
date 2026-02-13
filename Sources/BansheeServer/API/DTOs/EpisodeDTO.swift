import Vapor

struct EpisodeDTO: Content {
    let id: UUID
    let title: String
    let pubDate: Date
    let description: String
    
    let season: String?
    let episode: Int?
    
    let duration: Int?
    let audio: AudioDTO
    
    let podcastID: UUID
}

extension Episode {
    func toDTO() throws -> EpisodeDTO {
        try EpisodeDTO(
            id: requireID(),
            title: title,
            pubDate: pubDate,
            description: description,
            season: season,
            episode: episodeNumber,
            duration: duration,
            audio: audio.toDTO(),
            podcastID: $podcast.id
        )
    }
}
