import Vapor

enum AuthError {
    static var invalidAuth: Abort { Abort(.unauthorized, reason: "Authentication malformed or missing") }
    static var invalidRole: Abort { Abort(.forbidden, reason: "You must be an admin user to access this content") }
    static var invalidUsernameOrPassword: Abort { Abort(.unauthorized, reason: "Invalid username or password provided") }
}
