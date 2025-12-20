import Vapor

struct RSSConfigDTO: Content {
    let id: UUID
    let url: URL
    let lastFetched: Date
    let updateInterval: TimeInterval?

    var title: String?
    var podcastID: UUID?
}

extension RSSConfigDTO {
    init?(from config: RSSConfig?) throws {
        guard let config else { return nil }

        guard let id = config.id
        else { throw Abort(.internalServerError, reason: "Config not persisted before response.") }

        self.id = id
        self.url = config.url
        self.lastFetched = config.lastFetched
        self.updateInterval = config.updateInterval

        if config.$podcast.isLoaded {
            self.title = config.podcast.title
            self.podcastID = config.podcast.id
        }
    }
}