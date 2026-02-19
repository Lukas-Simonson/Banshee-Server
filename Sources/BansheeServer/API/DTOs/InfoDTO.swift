import Vapor

struct InfoDTO: Content {
    let name: String
    let service: String
    let version: String
}
