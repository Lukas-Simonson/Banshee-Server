import Vapor

struct EpisodeDTO: Content {
    let id: UUID
    var title: String
    let pubDate: Date
    var description: String
    var imageURL: URL?
    
    var season: String?
    var episode: Int?
    
    let duration: Int?
    let audio: AudioDTO?
    let progress: EpisodeProgressDTO?
    var config: EpisodeConfigDTO?
    
    let podcastID: UUID
}

extension Episode {
    func toDTO(configMode: ConfigMode, includeAudio: Bool, progress: EpisodeProgress? = nil) throws -> EpisodeDTO {
        var dto = try EpisodeDTO(
            id: requireID(),
            title: title,
            pubDate: pubDate,
            description: description,
            season: season,
            episode: episodeNumber,
            duration: duration,
            audio: !includeAudio ? nil : audio.toDTO(),
            progress: try? (progress ?? joined(EpisodeProgress.self)).toDTO(),
            config: config.toDTO(),
            podcastID: $podcast.id
        )
        
        switch configMode {
            case .none: dto.config = nil
            case .include: break
            case .override:
                dto.title ?= config.title
                dto.description ?= config.description
                dto.imageURL ?= config.imageURL
                dto.season ?= config.season
                dto.episode ?= config.episodeNumber
                dto.config = nil
        }
        
        return dto
    }
}
