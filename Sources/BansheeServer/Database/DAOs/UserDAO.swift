import Fluent
import Vapor

extension Request {
    var userDAO: UserDAO {
        UserDAO(db: self.db)
    }
}

struct UserDAO {
    let db: any Database
    
    func adminCount() async throws -> Int {
        try await User.query(on: db)
            .filter(\.$role == .admin)
            .count()
    }
    
    @discardableResult
    func create(email: String, username: String, name: String, passwordHash: String, role: User.Role) async throws -> User {
        let user = User(email: email, username: username, name: name, passwordHash: passwordHash, role: role)
        try await user.create(on: db)
        return user
    }
    
    func read(withEmailOrUsername identifier: String) async throws -> User? {
        try await User.query(on: db)
            .group(.or) { $0.filter(\.$username == identifier).filter(\.$email == identifier) }
            .first()
    }
}
