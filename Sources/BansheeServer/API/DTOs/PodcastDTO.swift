import Vapor

struct PodcastDTO: Content {
    let id: UUID
    var title: String
    let link: URI?
    let language: String
    var imageURL: URI?
    var description: String
    
    let feed: RSSFeedDTO?
    var config: PodcastConfigDTO?
    // let episodes: [EpisodeDTO]?
}

extension Podcast {
    func toDTO(configMode: ConfigMode) throws -> PodcastDTO {
        var dto = try PodcastDTO(
            id: requireID(),
            title: title,
            link: link,
            language: language,
            imageURL: imageURL,
            description: description,
            feed: $feed.value??.toDTO(),
            config: config.toDTO()
        )
        
        switch configMode {
            case .none: dto.config = nil
            case .include: break
            case .override:
                dto.title ?= config.title
                dto.imageURL ?= config.imageURL
                dto.description ?= config.description
                dto.config = nil
        }
        
        return dto
    }
}
