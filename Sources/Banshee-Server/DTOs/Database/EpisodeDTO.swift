import Vapor

struct EpisodeDTO: Content {
    var id: UUID
    var title: String
    var pubDate: Date
    var audioEnclosure: AudioEnclosureDTO
    var description: String
    var podcastID: UUID
    var config: EpisodeConfigDTO?
}

extension EpisodeDTO {
    init(from episode: Episode, overrideWithConfig: Bool = false) throws {
        guard let id = episode.id
        else { throw Abort(.internalServerError, reason: "Episode not persisted before response.") }

        self.id = id
        self.title = episode.title
        self.pubDate = episode.pubDate
        self.audioEnclosure = AudioEnclosureDTO(from: episode.audioEnclosure)
        self.description = episode.description
        self.podcastID = episode.$podcast.id

        self.config = episode.$config.isNotLoaded ? nil : try EpisodeConfigDTO(from: episode.config)

        if overrideWithConfig, let config {
            self.title ?= config.title
            self.description ?= config.description

            // Overriding with config excludes the config from the response.
            self.config = nil
        }
    }
}