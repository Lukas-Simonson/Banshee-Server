import Vapor

struct AudioEnclosureDTO: Content {
    var url: URL
    var length: Int64?
    var type: String
}

extension AudioEnclosureDTO {
    init(from enclosure: AudioEnclosure) {
        self.url = enclosure.url
        self.length = enclosure.length
        self.type = enclosure.type
    }
}