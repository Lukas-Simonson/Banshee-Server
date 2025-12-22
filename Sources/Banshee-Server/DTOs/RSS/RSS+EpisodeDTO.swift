import Vapor

extension RSS {
    struct EpisodeDTO: Content {
        let title: String
        let pubDate: Date
        let enclosure: EnclosureDTO
        let link: URL?
        let image: ImageDTO?
        let explicit: Bool?
        let season: String?
        let episode: Int?
        let description: String
    }
}

extension RSS.EpisodeDTO {
    func toModel() -> Episode {
        let episode = Episode()

        // print(image?.url)
        // print(explicit)

        episode.title = title
        episode.pubDate = pubDate
        episode.description = description
        episode.imageURL = image?.url
        episode.season = season
        episode.episodeNumber = self.episode

        return episode
    }
}