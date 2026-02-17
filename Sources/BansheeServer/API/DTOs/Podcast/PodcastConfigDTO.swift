import Vapor

struct PodcastConfigDTO: Content {
    let title: String?
    let imageURL: URI?
    let description: String?
}

extension PodcastConfigDTO {
    func toModel() -> PodcastConfig {
        PodcastConfig(
            title: title,
            imageURL: imageURL,
            description: description
        )
    }
}

extension PodcastConfig {
    func toDTO() -> PodcastConfigDTO? {
        guard title != nil || imageURL != nil || description != nil
        else { return nil }
        
        return PodcastConfigDTO(
            title: title,
            imageURL: imageURL,
            description: description
        )
    }
}

extension PodcastConfigDTO: Validatable {
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("title", as: String.self, required: false)
        validations.add("imageURL", as: String.self, is: .url, required: false)
        validations.add("description", as: String.self, required: false)
    }
}
