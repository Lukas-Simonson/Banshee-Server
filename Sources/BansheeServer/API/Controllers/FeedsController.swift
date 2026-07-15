import Vapor

/// Sets up RSS Feed Endpoints.
///
/// - `POST /api/podcasts/feeds`: Begins processing a collection of RSS feeds.
struct FeedsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped("feeds").group(UserToken.adminGuardMiddleware()) { feeds in
            feeds.post(use: register)
        }
    }
    
    /// Registers a podcasts RSS feed, downloading its metadata.
    ///
    /// Body: ``AddFeedRequest``
    ///
    /// - Returns: `201 Created` status with a ``PodcastDTO`` body.
    private func register(req: Request) async throws -> Response {
        try AddFeedRequest.validate(content: req)
        let feedRequest = try req.content.decode(AddFeedRequest.self)
        
        // Check if feed exists
        if try await req.rssFeedDAO.feed(with: feedRequest.url) != nil {
            throw FeedError.duplicateFeed
        }
        
        let rss = try await req.client.get(feedRequest.url)
            .content
            .decode(RSS.self)
        
        let feed = RSSFeed(url: feedRequest.url, downloadNew: feedRequest.autoDownload != .none)
        var podcast = rss.channel.toModel()
        let episodes = rss.channel.item.map { $0.toModel() }
        
        podcast = try await req.podcastDAO.create(podcast, from: feed, with: episodes)
        
        // Add downloads to queue if requested
        if feedRequest.autoDownload == .newAndExisting {
            // Run in a background task as this is not needed for the response.
            Task.detached(priority: .background) { [podcast] in
                do {
                    try await req.episodeDAO
                        .read(fromPodcastWithID: podcast.requireID(), includePodcast: true)
                        .compactMap { episode in
                            if let remote = episode.audio.remoteURL {
                                return EpisodeDownload(
                                    path: URL(string: req.application.downloadManager.path(for: episode))!,
                                    remote: remote,
                                    episode: episode
                                )
                            }
                            
                            return nil
                        }
                        .create(on: req.db)
                    
                    await req.application.downloadManager.start() // restart downloads if needed
                } catch {
                    req.logger.error("Failed to auto-queue downloads for podcast: \(podcast.id?.uuidString ?? "Unknown") | error: \(error)")
                }
            }
        }
  
        return try await podcast
            .toDTO(configMode: .none)
            .encodeResponse(status: .created, for: req)
    }
}

extension FeedsController {
    
    /// Request body intended for registering an RSS feed.
    struct AddFeedRequest: Content, Validatable {
        /// The URL of the RSS Feed.
        let url: URI
        
        /// How to automatically handle episode downloads.
        let autoDownload: DownloadMode
        
        static func validations(_ validations: inout Validations) {
            validations.add("url", as: String.self, is: .url)
            validations.add("autoDownload", as: String.self, is: .in("new", "new_and_existing", "none"))
        }
        
        enum DownloadMode: String, Content {
            case new = "new"
            case newAndExisting = "new_and_existing"
            case none = "none"
        }
    }
    
    enum FeedError {
        static var duplicateFeed: Abort { Abort(.badRequest, reason: "An RSS feed from this URL has already been created.") }
    }
}
