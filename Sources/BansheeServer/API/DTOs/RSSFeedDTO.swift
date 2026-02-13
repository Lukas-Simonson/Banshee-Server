import Vapor

struct RSSFeedDTO: Content {
    let id: UUID
    let podcastID: UUID
    let url: URI
    let lastFetched: Date
    let updateInterval: TimeInterval?
    
    let podcastTitle: String?
}

extension RSSFeed {
    func toDTO() throws -> RSSFeedDTO {
        RSSFeedDTO(
            id: try requireID(),
            podcastID: $podcast.id,
            url: url,
            lastFetched: lastFetched,
            updateInterval: updateInterval,
            podcastTitle: $podcast.value?.title
        )
    }
}
