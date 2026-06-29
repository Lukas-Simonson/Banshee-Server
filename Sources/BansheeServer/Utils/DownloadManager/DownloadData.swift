protocol DownloadData: Sendable {
    func readFreshDownloads(_ amount: Int) async throws -> [EpisodeDownload]
    func update(_ download: EpisodeDownload) async throws
}

extension EpisodeDownloadDAO: DownloadData {}
