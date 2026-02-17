import Vapor

struct EpisodeConfigDTO: Content {
    let title: String?
    let description: String?
    let imageURL: URI?
    let season: String?
    let episode: Int?
}

extension EpisodeConfigDTO {
    func toModel() -> EpisodeConfig {
        EpisodeConfig(
            title: title,
            description: description,
            imageURL: imageURL,
            season: season,
            episodeNumber: episode
        )
    }
}

extension EpisodeConfig {
    func toDTO() -> EpisodeConfigDTO? {
        guard title != nil || description != nil || imageURL != nil || season != nil || episodeNumber != nil
        else { return nil }
        
        return EpisodeConfigDTO(
            title: title,
            description: description,
            imageURL: imageURL,
            season: season,
            episode: episodeNumber
        )
    }
}

extension EpisodeConfigDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, required: false)
        validations.add("description", as: String.self, required: false)
        validations.add("imageURL", as: String.self, is: .url, required: false)
        validations.add("season", as: String.self, required: false)
        validations.add("episode", as: Int.self, required: false)
    }
}
