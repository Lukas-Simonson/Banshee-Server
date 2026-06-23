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
struct EpisodeDownloadDAO {
    let db: any Database
}
