import Foundation

extension FileManager {
    
    // Checks if a path exists and whether or not it is a directory.
    func pathExists(_ path: String) -> (exists: Bool, isDirectory: Bool) {
        var isDirectory = ObjCBool(false)
        let exists = self.fileExists(atPath: path, isDirectory: &isDirectory)
        return (exists, isDirectory.boolValue)
    }
}

enum FileUtils {
    nonisolated static func sanitize(_ name: String) -> String {
        name
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "..", with: "")
    }
    
    /// Provides a filetype extension from a mimetype. Defaults to mp3 if one cannot be found.
    nonisolated static func `extension`(from mimeType: String?) -> String {
        guard let type = mimeType?.lowercased() else { return ".mp3" }

        return switch type {
            case "audio/mpeg", "audio/mp3": "mp3"
            case "audio/mp4", "audio/m4a", "audio/x-m4a": "m4a"
            case "audio/ogg": "ogg"
            case "audio/wav": "wav"
            case "audio/aac": "aac"
            case "audio/flac": "flac"
            default: "mp3"
        }
    }
    
    /// Provides a folder name for an episode based on its season.
    nonisolated static func folderName(for episode: Episode) -> String {
        guard let season = episode.season else { return "Other" }

        if let number = Int(season) {
            return "Season \(pad(number))"
        }

        return sanitize(season)
    }
    
    
    /// Profiles a filename for an episode based on its season, episode, and title.
    ///
    /// Does **NOT** include the extension for the file.
    nonisolated static func filename(for episode: Episode) -> String {
        let season = if let number = Int(episode.season ?? "") {
            "[S\(pad(number))]"
        } else if let name = episode.season {
            "[\(name)]"
        } else {
            "[Other]"
        }
        
        let epNumber = if let number = episode.episodeNumber {
            "[E\(pad(number))]"
        } else {
            "[E???]"
        }
        
        return sanitize("\(season)\(epNumber) - \(episode.title)")
    }
    
    nonisolated static func pad(_ number: Int, by count: Int = 3) -> String {
        String(format: "%0\(count)d", number)
    }
}
