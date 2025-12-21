import Fluent
import Vapor

struct EpisodesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.grouped("episodes").group(UserAuthenticator()) { episodes in
            // NOTE: Will likely be used more for later. Used as a wrapper for now.
            try episodes.register(collection: EpisodeConfigController())
            try episodes.register(collection: EpisodeDownloadController())
            try episodes.register(collection: EpisodeAudioController())
        }
    }
}