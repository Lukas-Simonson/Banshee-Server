import Fluent
import Vapor

final class Podcast: Model, @unchecked Sendable {
    @ID
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "link")
    var link: URI?
    
    @Field(key: "language")
    var language: String
    
    @Field(key: "image_url")
    var imageURL: URI?
    
    @Field(key: "description")
    var description: String
    
    @Children(for: \.$podcast)
    var episodes: [Episode]
    
    init() {}
    
    init(title: String, link: URI?, language: String, imageURL: URI?, description: String) {
        self.title = title
        self.link = link
        self.language = language
        self.imageURL = imageURL
        self.description = description
    }
}

extension Podcast {
    static let schema = "podcast"
    
    enum Migration { }
}

extension Podcast.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("podcast")
                .id()
                .field("title", .string, .required)
                .field("link", .string)
                .field("language", .string, .required)
                .field("image_url", .string)
                .field("description", .string, .required)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("podcast").delete()
        }
    }
}
