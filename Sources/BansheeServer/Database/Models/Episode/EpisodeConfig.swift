import Fluent
import Vapor

final class EpisodeConfig: Fields, @unchecked Sendable {
    @Field(key: "title")
    var title: String?

    @Field(key: "description")
    var description: String?

    @Field(key: "image_url")
    var imageURL: URI?

    @Field(key: "season")
    var season: String?

    @Field(key: "episode_number")
    var episodeNumber: Int?
    
    init() {}
    
    init(title: String?, description: String?, imageURL: URI?, season: String?, episodeNumber: Int?) {
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.season = season
        self.episodeNumber = episodeNumber
    }
}
