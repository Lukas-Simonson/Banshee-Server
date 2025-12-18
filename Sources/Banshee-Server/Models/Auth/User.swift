import Fluent
import Foundation

final class User: Model, @unchecked Sendable {
    @ID
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "password")
    var password: String

    @Field(key: "role")
    var role: Role

    init() {}

    init(username: String, passwordHash: String, role: Role) {
        self.username = username
        self.password = passwordHash
        self.role = role
    }
}

// MARK: - Model Conformance
extension User {
    static let schema = "user"

    enum Migration { }
}

extension User.Migration {
    
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema("user")
                .id()
                .field("username", .string, .required).unique(on: "username")
                .field("password", .string, .required)
                .field("role", .string, .required)
                .create()   
        }

        func revert(on database: any Database) async throws {
            try await database.schema("user").delete()
        }
    }
}