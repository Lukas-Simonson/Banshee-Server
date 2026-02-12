import Vapor

struct PodcastDTO: Content {
    let id: UUID
    let title: String
    let link: URI?
    let language: String
    let imageURL: URI?
    let description: String
    
    // let config: PodcastConfigDTO?
    // let feed: RSSFeedDTO?
    // let episodes: [EpisodeDTO]?
}

extension Podcast {
    func toDTO() throws -> PodcastDTO {
        try PodcastDTO(
            id: requireID(),
            title: title,
            link: link,
            language: language,
            imageURL: imageURL,
            description: description
        )
    }
}
