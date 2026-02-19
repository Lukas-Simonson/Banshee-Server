import Fluent
import Vapor

/// The non-destructive server config for a podcast.
final class PodcastConfig: Fields, @unchecked Sendable {
    
    /// The title of the podcast.
    @Field(key: "title")
    var title: String?
    
    /// The cover art to use for this podcast.
    @Field(key: "image_url")
    var imageURL: URI?
    
    /// The description of the podcast.
    @Field(key: "description")
    var description: String?
    
    init() {}
    
    init(title: String?, imageURL: URI?, description: String?) {
        self.title = title
        self.imageURL = imageURL
        self.description = description
    }
}
