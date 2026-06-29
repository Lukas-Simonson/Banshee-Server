import Fluent
import FluentSQL
import Vapor

extension Request {
    /// An access object used to read ``EpisodeDownload`` information from a database.
    var episodeDownloadDAO: EpisodeDownloadDAO {
        EpisodeDownloadDAO(db: db)
    }
}

/// The access object used to read ``EpisodeDownload`` information from a database.
struct EpisodeDownloadDAO: Sendable {
    let db: any Database
    
    /// Reads `amount` ``EpisodeDownload`` filtering completed downloads, and sorting oldest to newest.
    func readFreshDownloads(_ amount: Int) async throws -> [EpisodeDownload] {
        try await EpisodeDownload.query(on: db)
            .filter(\.$finishedAt == nil)
            .sort(\.$queuedAt, .ascending)
            .limit(amount)
            .all()
    }
    
    /// Updates an ``EpisodeDownload``.
    func update(_ episode: EpisodeDownload) async throws {
        try await episode.update(on: db)
    }
}
