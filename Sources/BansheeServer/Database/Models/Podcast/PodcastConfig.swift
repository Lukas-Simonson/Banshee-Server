import Fluent
import Vapor

final class PodcastConfig: Fields, @unchecked Sendable {
    @Field(key: "title")
    var title: String?
    
    @Field(key: "image_url")
    var imageURL: URI?
    
    @Field(key: "description")
    var description: String?
    
    init() {}
    
    init(title: String?, imageURL: URI?, description: String?) {
        self.title = title
        self.imageURL = imageURL
        self.description = description
    }
}
