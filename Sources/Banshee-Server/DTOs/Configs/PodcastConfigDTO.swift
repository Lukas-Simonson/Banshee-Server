import Vapor

struct PodcastConfigDTO: Content {
    var title: String?
    var imageURL: URL?
    var description: String?
}

extension PodcastConfigDTO {
    init?(from config: PodcastConfig?) {
        guard let config else { return nil }

        self.title = config.title
        self.imageURL = config.imageURL
        self.description = config.description
    }

    func toModel(with id: UUID?) -> PodcastConfig {
        let config = PodcastConfig()

        if let id {
            config.id = id
            // Tell Fluent to update the model.
            config._$idExists = true
        }
        
        config.title = title
        config.imageURL = imageURL
        config.description = description

        return config
    }
}