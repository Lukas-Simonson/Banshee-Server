import Vapor

struct UserDTO: Content {
    let id: UUID
    let email: String
    let name: String
    let role: User.Role
    let token: String?
}

extension User {
    func toDTO(with token: String? = nil) throws -> UserDTO {
        try UserDTO(
            id: requireID(),
            email: email,
            name: name,
            role: role,
            token: token
        )
    }
}
