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