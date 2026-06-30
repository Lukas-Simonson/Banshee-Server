import Fluent
import _NIOFileSystem
import Vapor

/// Sets up the Download endpoints
///
/// - `POST /api/download`: Queues up downloads for the provided episodes
struct DownloadController: RouteCollection {
    
    /// Called to register the routes of the collection.
    func boot(routes: any RoutesBuilder) throws {
        routes.group("download") { download in
            download.post(use: download(req:))
        }
    }
    
    /// Queues downloads for episodes with the provided ids.
    ///
    /// Body: ``DownloadRequest``
    ///
    /// - Returns: `202 Accepted` status with a ``DownloadResponse`` body.
    private func download(req: Request) async throws -> Response {
        let downloadRequest = try req.content.decode(DownloadRequest.self)
        
        // Get the matching episodes
        let episodes = try await req.episodeDAO.readAll(in: downloadRequest.episodes, includeDownloads: true, includePodcast: true)
        
        var response = DownloadResponse(missing: Set(downloadRequest.episodes))
        var downloads = [EpisodeDownload]()
        
        for episode in episodes {
            let id = try episode.requireID()
            response.missing.remove(id)
            
            guard episode.download == nil
            else { response.duplicate.insert(id); continue }
            
            guard let audioURL = episode.audio.remoteURL
            else { response.missingAudio.insert(id); continue }
            
            let destination = req.application.downloadManager.path(for: episode)
            
            response.queued.insert(id)
            downloads.append(EpisodeDownload(
                path: URL(string: destination)!,
                remote: audioURL,
                episode: episode
            ))
        }
        
        try await downloads.create(on: req.db)
        await req.application.downloadManager.start()
        
        return try await response
            .encodeResponse(status: .accepted, for: req)
    }
}

extension DownloadController {
    
    /// Request body intended for queuing downloads.
    struct DownloadRequest: Content {
        
        /// Ids for all episodes requested to be downloaded
        let episodes: [UUID]
    }
    
    /// Response body for information about download requests.
    struct DownloadResponse: Content {
        
        /// The ids where no matching episode could be found.
        var missing = Set<UUID>()
        
        /// The ids where an episode was found, but no remote audio could be found to download.
        var missingAudio = Set<UUID>()
        
        /// The ids where a download was already queued or completed.
        var duplicate = Set<UUID>()
        
        /// The ids that were successfully queued for download.
        var queued = Set<UUID>()
    }
}
