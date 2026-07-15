import Vapor

struct AudioDTO: Content {
    let remoteURL: URI?
    let localURL: URL?
    let length: Int64?
    let type: String?
}

extension Audio {
    func toDTO() -> AudioDTO {
        AudioDTO(
            remoteURL: remoteURL,
            localURL: localURL,
            length: length,
            type: type
        )
    }
}
