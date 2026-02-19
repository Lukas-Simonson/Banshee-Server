import Vapor

enum FileError {
    
    /// `503 Service Unavailable`, no audio file is provided either from the local or remote sources.
    static var noAudioFiles: Abort { Abort(.serviceUnavailable, reason: "No audio sources are configured for this resource.") }
}
