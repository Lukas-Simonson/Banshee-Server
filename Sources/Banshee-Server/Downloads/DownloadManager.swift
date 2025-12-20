import Vapor

/// Manages large file downloads, specifically focused on Podcast Episodes for the moment.
actor DownloadManager {

    /// Current Download Tasks, keyed by the id of the episode that is being downloaded.
    private(set) var tasks = [UUID: FileDownload]()

    func download(episode: Episode) async throws {
        
    }
}