import Vapor

extension RSS {
    struct EnclosureDTO: Content {
        let url: URL
        let length: UInt64?
        let type: String
    }
}