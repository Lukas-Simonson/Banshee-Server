import Vapor

struct PodcastDTO: Content {
    var id: UUID
    var rssFeedURL: URL?
    var title: String
    var link: URL?
    var language: String
    var imageURL: URL?
    var description: String
    var config: PodcastConfigDTO?
    var episodes: [EpisodeDTO]?
}

extension PodcastDTO {
    init(from podcast: Podcast, with episodes: [EpisodeDTO]? = nil, overrideWithConfig: Bool = false) throws {
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
        
        // Verify if config was eager-loaded.
        self.config = podcast.$config.isNotLoaded ? nil : PodcastConfigDTO(from: podcast.config)

        if overrideWithConfig, let config {
            self.title ?= config.title
            self.imageURL ?= config.imageURL
            self.description ?= config.description
            
            // Overriding with config excludes the config from the response.
            self.config = nil
        }
    }
}