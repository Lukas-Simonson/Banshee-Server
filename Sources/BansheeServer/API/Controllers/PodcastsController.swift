import Vapor

/// Sets up the Podcast endpoints
///
/// - `GET /api/podcasts`: Gets all available podcasts.
/// - `GET /api/podcasts/:podcastID`: Get information for a single podcast.
/// - `DELETE /api/podcasts/:podcastID`: Deletes a podcast.
/// - `GET /api/podcasts/:podcastID/episodes`: Gets all episodes in a podcast.
struct PodcastsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        try routes.group("podcasts") { podcasts in
            podcasts.get(use: getAllPodcasts)
            
            try podcasts.register(collection: FeedsController())
            
            podcasts.group(":podcastID") { podcastID in
                podcastID.get(use: getPodcast)
                podcastID.get("episodes", use: getEpisodes)
                
                podcastID.group(UserToken.adminGuardMiddleware()) { podcastIDAdmin in
                    podcastIDAdmin.delete(use: deletePodcast)
                }
            }
        }
    }
    
    private func getAllPodcasts(req: Request) async throws -> Response {
        return Response(status: .notImplemented)
    }
    
    private func getPodcast(req: Request) async throws -> Response {
        return Response(status: .notImplemented)
    }
    
    private func getEpisodes(req: Request) async throws -> Response {
        return Response(status: .notImplemented)
    }
    
    private func deletePodcast(req: Request) async throws -> Response {
        return Response(status: .notImplemented)
    }
}
