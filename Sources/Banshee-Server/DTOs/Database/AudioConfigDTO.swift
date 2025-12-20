import Vapor

struct AudioConfigDTO: Content {
    var id: UUID
    var remoteURL: URL?
    var localURL: URL?
    var length: Int64?
    var type: String?
    var episodeID: UUID
}

extension AudioConfigDTO {
    init?(from config: AudioConfig?) throws {
        guard let config else { return nil }

        guard let id = config.id
        else { throw Abort(.internalServerError, reason: "AudioConfig not persisted before response.") }

        self.id = id
        self.remoteURL = config.remoteURL
        self.localURL = config.localURL
        self.length = config.length
        self.type = config.type
        self.episodeID = config.$episode.id
    }
}