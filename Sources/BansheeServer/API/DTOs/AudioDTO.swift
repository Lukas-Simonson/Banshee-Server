import Vapor

struct AudioDTO: Content {
    let remoteURL: URI?
    let localURL: URI?
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
