import Vapor

struct EpisodeDTO: Content {
    var id: UUID
    var title: String
    var pubDate: Date
    var audioEnclosure: AudioEnclosureDTO
    var description: String
    var podcastID: UUID
}

extension EpisodeDTO {
    init(from episode: Episode, podcastID: UUID) throws {
        guard let id = episode.id
        else { throw Abort(.internalServerError, reason: "Episode not persisted before response.") }

        self.id = id
        self.title = episode.title
        self.pubDate = episode.pubDate
        self.audioEnclosure = AudioEnclosureDTO(from: episode.audioEnclosure)
        self.description = episode.description
        self.podcastID = podcastID
    }
}