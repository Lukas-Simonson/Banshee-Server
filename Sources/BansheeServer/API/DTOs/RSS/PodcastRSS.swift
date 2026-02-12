import Vapor

struct PodcastRSS: Content {
    let title: String
    let link: URI?
    let language: String
    let copyright: String?
    let image: ImageRSS?
    let description: String
    let item: [EpisodeRSS]
}

extension PodcastRSS {
    func toModel() -> Podcast {
        Podcast(
            title: title,
            link: link,
            language: language,
            imageURL: image?.url,
            description: description
        )
    }
}
