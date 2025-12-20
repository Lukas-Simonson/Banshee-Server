import Vapor

extension RSS {
    struct EnclosureDTO: Content {
        let url: URL
        let length: Int64?
        let type: String
    }
}

extension RSS.EnclosureDTO {
    func toModel() -> AudioConfig {
        let enclosure = AudioConfig()

        enclosure.remoteURL = url
        enclosure.length = length
        enclosure.type = type

        return enclosure
    }
}