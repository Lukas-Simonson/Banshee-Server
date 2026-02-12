import Fluent
import Vapor

final class Audio: Fields, @unchecked Sendable {
    @Field(key: "remote_url")
    var remoteURL: URI?
    
    @Field(key: "local_url")
    var localURL: URI?
    
    @Field(key: "length")
    var length: Int64?
    
    @Field(key: "type")
    var type: String?
    
    init() {}
    
    init(remoteURL: URI? = nil, localURL: URI? = nil, length: Int64? = nil, type: String? = nil) {
        self.remoteURL = remoteURL
        self.localURL = localURL
        self.length = length
        self.type = type
    }
}
