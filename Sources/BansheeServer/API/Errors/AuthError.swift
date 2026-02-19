import Vapor

enum AuthError {
    
    /// `401 Unauthorized`, missing or malformed authentication.
    static var invalidAuth: Abort { Abort(.unauthorized, reason: "Authentication malformed or missing") }
    
    /// `403 Forbidden`, admin only content.
    static var adminOnlyContent: Abort { Abort(.forbidden, reason: "You must be an admin user to access this content") }
    
    /// `401 Unauthorized`, invalid username or password provided.
    static var invalidUsernameOrPassword: Abort { Abort(.unauthorized, reason: "Invalid username or password provided") }
}
