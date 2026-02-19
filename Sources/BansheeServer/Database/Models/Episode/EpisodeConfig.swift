import Fluent
import Vapor

/// The non-destructive server config for an episode.
final class EpisodeConfig: Fields, @unchecked Sendable {
    
    /// The title of the episode.
    @Field(key: "title")
    var title: String?

    /// The description of the episode.
    @Field(key: "description")
    var description: String?

    /// An image to use for the episode cover art.
    @Field(key: "image_url")
    var imageURL: URI?

    /// The season of the episode.
    @Field(key: "season")
    var season: String?

    /// The episode number.
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
