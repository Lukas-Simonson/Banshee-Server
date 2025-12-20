import Vapor

enum ConfigMode: String, Content {
    case none
    case include
    case override
}