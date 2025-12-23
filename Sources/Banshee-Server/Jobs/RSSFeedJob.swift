import Fluent
import Queues
import Vapor


struct RSSFeedJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        // Pull feeds from db.
        let feeds = try await RSSConfig.query(on: context.application.db)
            .filter(\.$updateInterval != nil)
            .with(\.$podcast) { podcast in
                podcast.with(\.$episodes)
            }
            .all()
            .filter { $0.isExpired }

        context.application.logger.info("Updating \(feeds.count) RSS Feeds")

        // Update feeds.
        await withDiscardingTaskGroup { group in
            for feed in feeds {
                group.addTask {
                    do {
                        try await updateFeed(
                            feed, 
                            client: context.application.client,
                            db: context.application.db
                        ) 
                        context.application.logger.info("Successfully updated feed with id: \(feed.id!)")
                    } catch {
                        context.application.logger.error("Error updating feed with id: \(feed.id!) - \(error)")
                    }
                }
            }
        }
    }

    private func updateFeed(
        _ feed: RSSConfig, 
        client: any Client,
        db: any Database
    ) async throws {
        // Get feed from internet
        let rssResponse = try await client.get(URI(from: feed.url))
            .content.decode(RSS.self)

        if feed.podcast != rssResponse.channel {
            feed.podcast.update(from: rssResponse.channel)
            try await feed.podcast.update(on: db)
        }

        // Pair episodes on title
        var episodes = [String: (Episode?, RSS.EpisodeDTO?)]()

        for episode in feed.podcast.episodes {
            episodes[episode.title] = (episode, nil)
        }

        for episode in rssResponse.channel.item {
            episodes[episode.title, default: (nil, nil)].1 = episode
        }

        // Update episodes that have changed
        for (_, (episode, dto)) in episodes {
            if let episode, let dto, episode != dto {
                episode.update(from: dto)
                try await episode.save(on: db)
            } else if episode == nil, let dto {
                // New Episode
                let model = dto.toModel()
                try await feed.podcast.$episodes.create(model, on: db)
                try await model.$audioConfig.create(dto.enclosure.toModel(), on: db)
            }
        }

        feed.lastFetched = .now
        try await feed.update(on: db)
    }
}

extension RSSConfig {
    var isExpired: Bool {
        guard let updateInterval else { return false }

        return lastFetched.advanced(by: updateInterval) < .now
    }
}