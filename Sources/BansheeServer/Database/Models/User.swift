import Fluent
import Foundation
import Vapor

final class User: Model, @unchecked Sendable {
    @ID
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "passwordHash")
    var passwordHash: String
    
    @Field(key: "role")
    var role: Role
    
    init() { }
    
    init(email: String, name: String, passwordHash: String, role: Role) {
        self.email = email
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

extension User: ModelAuthenticatable {
    typealias AuthKeypath = KeyPath<User, FieldProperty<User, String>>
    
    static let usernameKey: AuthKeypath = \User.$name
    static let passwordHashKey: AuthKeypath = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: passwordHash)
    }
}

extension User.Migration {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("user")
                .id()
                .field("email", .string, .required).unique(on: "email")
                .field("name", .string, .required).unique(on: "name")
                .field("password", .string, .required)
                .field("role", .string, .required)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("user").delete()
        }
    }
}
