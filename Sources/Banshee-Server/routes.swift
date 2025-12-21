import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.group("api") { api in
        try api.register(collection: AuthController())
        try api.register(collection: PodcastsController())
        try api.register(collection: EpisodesController())
        try api.register(collection: InfoController())
    }
}
