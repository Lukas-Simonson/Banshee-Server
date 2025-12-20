import Vapor

extension RSS {
    struct EpisodeDTO: Content {
        let title: String
        let pubDate: Date
        let enclosure: EnclosureDTO
        let link: URL?
        let season: String?
        let episode: Int?
        let description: String
    }
}

extension RSS.EpisodeDTO {
    func toModel() -> Episode {
        let episode = Episode()

        episode.title = title
        episode.pubDate = pubDate
        episode.description = description
        episode.season = season
        episode.episodeNumber = self.episode

        return episode
    }
}