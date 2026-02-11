import Fluent
import Vapor

func routes(_ app: Application) throws {
    // MARK: - API
    try app.group("api") { api in
        try api.register(collection: AuthController())
    }
}
