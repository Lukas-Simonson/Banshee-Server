import Fluent
import Vapor

func routes(_ app: Application) throws {
    // MARK: - API
    try app.group("api") { api in
        try api.register(collection: AuthController())
        
        // All Protected Endpoints
        try api.grouped(UserAuthenticator()).group(UserToken.guardMiddleware()) { api in
            try api.register(collection: PodcastsController())
        }
    }
}
