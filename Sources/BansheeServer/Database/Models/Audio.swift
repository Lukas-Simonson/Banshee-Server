import Fluent
import Vapor

/// Audio information containing both local and remote sources.
final class Audio: Fields, @unchecked Sendable {
    
    /// The remote / source location of the audio file.
    @OptionalField(key: "remote_url")
    var remoteURL: URI?
    
    /// The local / cached location of the audio file.
    @OptionalField(key: "local_url")
    var localURL: URI?
    
    /// The size of the audio file in bytes.
    @OptionalField(key: "length")
    var length: Int64?
    
    /// The type of audio.
    @OptionalField(key: "type")
    var type: String?
    
    init() {}
    
    init(remoteURL: URI? = nil, localURL: URI? = nil, length: Int64? = nil, type: String? = nil) {
        self.remoteURL = remoteURL
        self.localURL = localURL
        self.length = length
        self.type = type
    }
}
