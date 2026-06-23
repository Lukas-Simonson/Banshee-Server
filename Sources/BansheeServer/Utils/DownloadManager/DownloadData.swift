protocol DownloadData: Sendable {
    func readFreshDownloads(_ amount: Int) async throws -> [EpisodeDownload]
    func updateProgress(on download: EpisodeDownload) async throws
}

extension EpisodeDownloadDAO: DownloadData {}
