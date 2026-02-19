import Fluent
import Vapor

extension Request {
    /// An access object used to read ``User`` information from a database.
    var userDAO: UserDAO {
        UserDAO(db: self.db)
    }
}

/// The access object used to read ``User`` information from a database.
struct UserDAO {
    
    /// The database to read from.
    let db: any Database
    
    /// Reads the number of users with the `admin` role.
    func adminCount() async throws -> Int {
        try await User.query(on: db)
            .filter(\.$role == .admin)
            .count()
    }
    
    /// Creates and returns a `User` from its components.
    @discardableResult
    func create(email: String, username: String, name: String, passwordHash: String, role: User.Role) async throws -> User {
        let user = User(email: email, username: username, name: name, passwordHash: passwordHash, role: role)
        try await user.create(on: db)
        return user
    }
    
    /// Reads a user with a matching email or username.
    func read(withEmailOrUsername identifier: String) async throws -> User? {
        try await User.query(on: db)
            .group(.or) { $0.filter(\.$username == identifier).filter(\.$email == identifier) }
            .first()
    }
}
