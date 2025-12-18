import Fluent
import Vapor

final class AudioEnclosure: Fields, @unchecked Sendable {
    @Field(key: "url")
    var url: URL

    @Field(key: "length")
    var length: Int64?

    @Field(key: "type")
    var type: String
}