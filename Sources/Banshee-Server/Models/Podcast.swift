import Fluent
import Foundation

final class Podcast: Model, @unchecked Sendable {
    @ID
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "link")
    var link: URL?

    @Field(key: "language")
    var language: String
    
    @Field(key: "imageURL")
    var imageURL: URL?

    @Field(key: "description")
    var description: String

    // MARK: Relationships

    @OptionalChild(for: \.$podcast)
    var config: PodcastConfig?

    @OptionalChild(for: \.$podcast)
    var rssConfig: RSSConfig?

    @Children(for: \.$podcast)
    var episodes: [Episode]
}

extension Podcast {
    func update(from dto: RSS.PodcastDTO) {
        self.title = dto.title
        self.link = dto.link
        self.language = dto.language
        self.imageURL = dto.image?.url
        self.description = dto.description
    }

    static func == (lhs: Podcast, rhs: RSS.PodcastDTO) -> Bool {
        lhs.title == rhs.title && lhs.link == rhs.link &&
        lhs.language == rhs.language && lhs.imageURL == rhs.image?.url &&
        lhs.description == rhs.description
    }

    static func != (lhs: Podcast, rhs: RSS.PodcastDTO) -> Bool {
        lhs.title != rhs.title || lhs.link != rhs.link ||
        lhs.language != rhs.language || lhs.imageURL != rhs.image?.url ||
        lhs.description != rhs.description
    }
}

// MARK: - Model Conformance
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
                .field("imageURL", .string)
                .field("description", .string, .required)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("podcast").delete()
        }
    }
}