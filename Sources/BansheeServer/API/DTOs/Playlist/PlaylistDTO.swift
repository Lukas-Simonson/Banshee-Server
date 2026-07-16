import Vapor

struct PlaylistDTO: Content {
    let id: UUID
    let title: String
    let imageURL: URL?
    let description: String?
    let isPublic: Bool
    let episodes: [PlaylistEpisodeDTO]?
}

extension Playlist {
    func toDTO() throws -> PlaylistDTO {
        try PlaylistDTO(
            id: requireID(),
            title: title,
            imageURL: imageURL,
            description: description,
            isPublic: isPublic,
            episodes: $episodes.value?.map { try $0.toDTO() }
        )
    }
}
