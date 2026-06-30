import Fluent
import Queues
import Vapor

struct UpdateFeedJob: AsyncScheduledJob {
    func run(context: Queues.QueueContext) async throws {
        // Pull feeds from DB
        let dao = RSSFeedDAO(db: context.application.db)
        let expired = try await dao.expiredFeeds()
        context.logger.info("Updating \(expired.count) feeds.")
        
        // Update each feed
        await withDiscardingTaskGroup { group in
            for feed in expired {
                group.addTask {
                    do {
                        try await updateFeed(feed, context: context)
                        context.logger.info("Successfully updated feed: \(feed.id!)")
                    } catch {
                        context.logger.error("Error updating feed: \(feed.id!) | error: \(error)")
                    }
                }
            }
        }
    }
    
    private func updateFeed(_ feed: RSSFeed, context: Queues.QueueContext) async throws {
        // Fetch remote feed
        let rss = try await context.application.client.get(feed.url)
            .content
            .decode(RSS.self)
        
        let updates = rss.channel.item
        
        // Map current episodes to GUID
        let episodes = feed.podcast.episodes.keyed { episode in
            episode.guid
        }
        
        for update in updates {
            if let current = episodes[update.guid] {
                guard current != update else { continue }
                current.update(from: update)
                try await current.save(on: context.application.db)
            } else { // New episode
                let model = update.toModel()
                try await feed.podcast.$episodes.create(model, on: context.application.db) // Could probably be batched to be faster.
            }
        }
        
        feed.lastFetched = .now
        try await feed.update(on: context.application.db)
    }
}
