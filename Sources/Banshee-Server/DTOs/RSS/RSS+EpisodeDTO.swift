import Vapor

extension RSS {
    struct EpisodeDTO: Content {
        let title: String
        let pubDate: Date
        let enclosure: EnclosureDTO
        let link: URL?
        let description: String
    }
}

extension RSS.EpisodeDTO {
    func toModel() -> Episode {
        let episode = Episode()

        episode.title = title
        episode.pubDate = pubDate
        episode.description = description

        return episode
    }
}