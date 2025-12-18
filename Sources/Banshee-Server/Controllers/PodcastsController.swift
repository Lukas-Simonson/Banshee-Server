import Vapor

struct PodcastsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let podcasts = routes.grouped("podcasts")

        podcasts.group("feeds") { feeds in
            
        }
    }
}

// MARK: - Request Objects
extension PodcastsController {
    struct CreatePodcastFeedRequest: Content {
        let url: URL
    } 
}
