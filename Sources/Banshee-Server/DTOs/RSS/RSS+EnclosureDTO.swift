import Vapor

extension RSS {
    struct EnclosureDTO: Content {
        let url: URL
        let length: Int64?
        let type: String
    }
}

extension RSS.EnclosureDTO {
    func toModel() -> AudioEnclosure {
        let enclosure = AudioEnclosure()

        enclosure.url = url
        enclosure.length = length
        enclosure.type = type

        return enclosure
    }
}