import Vapor

struct EpisodeRSS: Content {
    let guid: String
    let title: String
    let pubDate: Date
    let enclosure: EnclosureRSS
    let link: URL?
    let image: ImageRSS?
    let season: String?
    let episode: Int?
    let description: String
    let duration: String?
}

extension EpisodeRSS {
    func toModel() -> Episode {
        Episode(
            guid: guid,
            title: title,
            pubDate: pubDate,
            description: description,
            season: season,
            episodeNumber: episode,
            duration: duration?.seconds,
            audio: enclosure.toModel()
        )
    }
}
