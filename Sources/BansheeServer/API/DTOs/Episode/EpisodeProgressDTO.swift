import Vapor

struct EpisodeProgressDTO: Content {
    let id: UUID
    let isCompleted: Bool
    let watchTime: Int
    let startedOn: Date
    let lastUpdated: Date
    
    let userID: UUID
    let episodeID: UUID
}

extension EpisodeProgress {
    func toDTO() throws -> EpisodeProgressDTO {
        try EpisodeProgressDTO(
            id: requireID(),
            isCompleted: isCompleted,
            watchTime: watchTime,
            startedOn: startedOn,
            lastUpdated: lastUpdated,
            userID: $user.id,
            episodeID: $episode.id
        )
    }
}
