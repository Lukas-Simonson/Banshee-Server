import JWT
import Vapor

/// A representation of a decoded JWT for a ``User``.
struct UserToken: JWTPayload, Authenticatable {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var role: User.Role
    
    /// The id of the user this token is used to authenticate for.
    var userID: UUID? {
        UUID(uuidString: subject.value)
    }
    
    /// Creates a token using a provided ``User``.
    init(for user: User) throws {
        self.subject = try SubjectClaim(value: user.requireID().uuidString)
        
        // TODO: Setup Expiration Proper
        self.expiration = ExpirationClaim(value: .distantFuture)
        self.role = user.role
    }
    
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}

extension User {
    
    /// Creates a `UserToken` for the user.
    func token() throws -> UserToken {
        try UserToken(for: self)
    }
}
