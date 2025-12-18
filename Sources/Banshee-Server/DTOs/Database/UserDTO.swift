import Vapor

struct UserDTO: Content {
    let id: UUID
    let username: String
    let role: Role
    let token: String?

    init(from user: User, with token: String? = nil) throws {
        guard let id = user.id
        else { throw Abort(.internalServerError, reason: "User not persisted before response.") }

        self.id = id
        self.username = user.username
        self.role = user.role
        self.token = token
    }
}