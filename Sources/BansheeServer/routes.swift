import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.group("api") { api in
        try api.register(collection: AuthController())
        try api.register(collection: InfoController())
        
        // All User Protected Endpoints
        try api.grouped(UserAuthenticator()).group(UserToken.guardMiddleware()) { api in
            try api.register(collection: PodcastsController())
            try api.register(collection: EpisodesController())
        }
        
        // Root Admin Protected Endpoints
        try api.grouped(UserAuthenticator()).group(UserToken.adminGuardMiddleware()) { api in
            try api.register(collection: DownloadController())
        }
        
        // Special Audio Streaming Routes
        try api.grouped(UserQueryAuthenticator()).group(UserToken.guardMiddleware()) { api in
            try api.group("episodes", ":episodeID") { episodeID in
                try episodeID.register(collection: EpisodeAudioController())
            }
        }
    }
}
