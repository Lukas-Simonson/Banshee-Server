import Vapor

extension RSS {
    struct ImageDTO: Content {
        let url: URL
        let link: URL?
        let title: String
    }   
}