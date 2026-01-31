import Vapor

struct EpisodeDTO: Content {
    var id: UUID
    var title: String
    var pubDate: Date
    var description: String
    var imageURL: URL?
    var season: String?
    var episodeNumber: Int?
    var duration: Int?

    var podcastID: UUID
    
    var config: EpisodeConfigDTO?
    var audio: AudioConfigDTO?
}

extension EpisodeDTO {
    init(from episode: Episode, overrideWithConfig: Bool = false) throws {
        guard let id = episode.id
        else { throw Abort(.internalServerError, reason: "Episode not persisted before response.") }

        self.id = id
        self.title = episode.title
        self.pubDate = episode.pubDate
        self.description = episode.description
        self.season = episode.season
        self.episodeNumber = episode.episodeNumber
        self.duration = episode.duration

        self.podcastID = episode.$podcast.id

        self.config = episode.$config.isNotLoaded ? nil : try EpisodeConfigDTO(from: episode.config)
        self.audio = episode.$audioConfig.isNotLoaded ? nil : try AudioConfigDTO(from: episode.audioConfig)

        if overrideWithConfig, let config {
            self.title ?= config.title
            self.description ?= config.description
            self.imageURL = config.imageURL
            self.season ?= config.season
            self.episodeNumber ?= config.episodeNumber

            // Overriding with config excludes the config from the response.
            self.config = nil
        }
    }
}
