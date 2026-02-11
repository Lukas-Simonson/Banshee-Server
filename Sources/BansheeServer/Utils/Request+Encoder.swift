import Vapor

extension Request {
    var contentEncoder: any ContentEncoder {
        get throws {
            try ContentConfiguration.global.requireEncoder(for: headers.accept.mediaTypes.first ?? .json)
        }
    }
}
