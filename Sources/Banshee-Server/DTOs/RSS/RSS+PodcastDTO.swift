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