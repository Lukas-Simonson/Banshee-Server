import Fluent
import Vapor

struct EpisodeAudioController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group(":episodeID", "audio") { audio in
            audio.get(use: streamEpisode)
        }
    }

    private func streamEpisode(req: Request) async throws -> Response {
        guard let id = req.parameters.get("episodeID", as: UUID.self)
        else { throw Errors.invalidIDFormat }

        let audio = try await AudioConfig.query(on: req.db)
            .filter(\.$episode.$id == id)
            .first()
            .unwrap(or: Errors.unknownID)

        guard let localURL = audio.localURL
        else { throw Errors.fileNotDownloaded }

        guard await req.downloadManager.tasks[id] == nil
        else { throw Errors.filePartiallyDownloaded }

        req.logger.info("Streaming audio file from: \(localURL)")

        return try await req.fileio.asyncStreamFile(at: localURL)
    }
}

extension EpisodeAudioController {
    enum Errors {
        static var unknownID: Abort { PodcastsController.Errors.unknownID }
        static var invalidIDFormat: Abort { PodcastsController.Errors.invalidIDFormat }
        static var fileNotDownloaded: Abort { Abort(.unprocessableEntity, reason: "Audio file has not been downloaded. Unable to stream.") }
        static var filePartiallyDownloaded: Abort { Abort(.unprocessableEntity, reason: "Audio file is partially downloaded. Unable to stream.") }
    }
}