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
    }
}
