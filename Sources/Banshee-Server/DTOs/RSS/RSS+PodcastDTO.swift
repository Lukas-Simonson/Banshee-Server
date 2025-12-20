import Vapor

extension RSS {
    struct PodcastDTO: Content {
        let title: String
        let link: URL?
        let language: String
        let copyright: String?
        let image: ImageDTO?
        let description: String
        let item: [EpisodeDTO]
    }
}

extension RSS.PodcastDTO {
    func toModel() -> Podcast {
        let podcast = Podcast()

        podcast.title = title
        podcast.link = link
        podcast.language = language
        podcast.imageURL = image?.url
        podcast.description = description

        return podcast
    }
}