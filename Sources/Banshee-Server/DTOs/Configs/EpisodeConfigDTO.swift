import Vapor

struct EpisodeConfigDTO: Content {
    var id: UUID?
    var title: String?
    var description: String?
    var imageURL: URL?
    var season: String?
    var episodeNumber: Int?
    var episodeID: UUID?
}

extension EpisodeConfigDTO {
    init?(from config: EpisodeConfig?) throws {
        guard let config else { return nil }

        guard let id = config.id
        else { throw Abort(.internalServerError, reason: "EpisodeConfig not persisted before response.") }

        self.id = id
        self.title = config.title
        self.description = config.description
        self.imageURL = config.imageURL
        self.season = config.season
        self.episodeNumber = config.episodeNumber
        self.episodeID = config.$episode.id
    }

    func toModel(with id: UUID?) -> EpisodeConfig {
        let config = EpisodeConfig()

        if let id {
            config.id = id
            // Tell Fluent we can update this model.
            config._$idExists = true
        }

        config.title = title
        config.description = description
        config.imageURL = imageURL
        config.season = season
        config.episodeNumber = episodeNumber

        return config
    }
}