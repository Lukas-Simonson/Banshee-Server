import Fluent
import Foundation
import Vapor

/// A user of the server.
final class User: Authenticatable, Model, @unchecked Sendable {
    
    /// The unique identifier used by the server.
    @ID
    var id: UUID?
    
    /// The email address of the user.
    @Field(key: "email")
    var email: String
    
    /// The username of the user.
    @Field(key: "username")
    var username: String
    
    /// The full name of the user.
    @Field(key: "name")
    var name: String
    
    /// The hash of the user's password.
    @Field(key: "password_hash")
    var passwordHash: String
    
    /// The role of the user on the server.
    @Field(key: "role")
    var role: Role
    
    /// Progress for all episodes the user has watched.
    @Children(for: \.$user)
    var episodeProgresses: [EpisodeProgress]
    
    init() { }
    
    init(email: String, username: String, name: String, passwordHash: String, role: Role) {
        self.email = email
        self.username = username
        self.name = name
        self.passwordHash = passwordHash
        self.role = role
    }
}

extension User {
    static let schema = "user"
    
    enum Migration { }
    
    enum Role: String, Content {
        case user
        case admin
    }
}

extension User.Migration {
    
    /// Creates the user table.
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("user")
                .id()
                .field("email", .string, .required).unique(on: "email")
                .field("username", .string, .required).unique(on: "username")
                .field("name", .string, .required)
                .field("password_hash", .string, .required)
                .field("role", .string, .required)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("user").delete()
        }
    }
}
