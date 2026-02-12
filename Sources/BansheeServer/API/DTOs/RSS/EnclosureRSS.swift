import Vapor

struct EnclosureRSS: Content {
    let url: URI
    let length: Int64?
    let type: String
}

extension EnclosureRSS {
    func toModel() -> Audio {
        Audio(
            remoteURL: url,
            localURL: nil,
            length: length,
            type: type
        )
    }
}
