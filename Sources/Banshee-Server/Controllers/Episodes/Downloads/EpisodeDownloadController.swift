import Fluent
import Vapor

struct EpisodeDownloadController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped("downloads").group(AdminAuthMiddleware()) { downloads in
            downloads.post(use: queueDownload)
        }
    }

    private func queueDownload(req: Request) async throws -> QueueEpisodeDownloadsResponse {
        let queueRequest = try req.content.decode(QueueEpisodeDownloadsRequest.self)

        let configs = try await AudioConfig.query(on: req.db)
            .filter(\.$episode.$id ~~ queueRequest.episodeIDs)
            .filter(\.$localURL == nil) // Only include non-downloaded files.
            .with(\.$episode) { episode in
                episode.with(\.$config)
                episode.with(\.$podcast)
            }
            .all()

        var requests = [DownloadRequest]()
        var results = QueueEpisodeDownloadsResponse()

        for config in configs {
            guard let id = config.episode.id else { continue }
            guard let remoteURL = config.remoteURL else {
                results.failed[id] = "No remote location found in audio config."
                continue
            }

            let podcastFolder = config.episode.podcast.title
            let seasonFolder = FileUtils.folderName(for: config.episode)
            let episodeFileName = FileUtils.filename(for: config.episode)
            let fileExtension = FileUtils.extension(from: config.type)

            let destination = "\(req.downloadManager.storageBasePath)/\(podcastFolder)/\(seasonFolder)/\(episodeFileName).\(fileExtension)"

            // NOTE: This is very slow, find a better way to handle this situation.
            config.localURL = destination
            try await config.save(on: req.db)
            
            results.started.append(id)
            requests.append(
                DownloadRequest(
                    id: id, 
                    remoteURL: remoteURL, 
                    destinationPath: destination, 
                )
            )
        }
        
        try await req.downloadManager.download(requests)

        return results
    }
}

extension EpisodeDownloadController {
    enum Errors {
        
    }
}

// MARK: - Request Objects
extension EpisodeDownloadController {
    struct QueueEpisodeDownloadsRequest: Content {
        let episodeIDs: [UUID]
    } 
}

// MARK: - Response Objects
extension EpisodeDownloadController {
    struct QueueEpisodeDownloadsResponse: Content {
        var started = [UUID]()
        var failed = [UUID: String]()
    }
}