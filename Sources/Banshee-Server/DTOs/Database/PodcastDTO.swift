import Vapor

struct PodcastDTO: Content {
    var id: UUID
    var rssFeedURL: URL?
    var title: String
    var link: URL?
    var language: String
    var imageURL: URL?
    var description: String
    var episodes: [EpisodeDTO]?
}

extension PodcastDTO {
    init(from podcast: Podcast, with episodes: [EpisodeDTO]? = nil) throws {
        guard let id = podcast.id
        else { throw Abort(.internalServerError, reason: "Podcast not persisted before response.") }

        self.id = id
        self.rssFeedURL = podcast.rssFeedURL
        self.title = podcast.title
        self.link = podcast.link
        self.language = podcast.language
        self.imageURL = podcast.imageURL
        self.description = podcast.description
        self.episodes = episodes
    }
}