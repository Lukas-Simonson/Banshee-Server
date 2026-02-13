import JWT
import Vapor

struct UserToken: JWTPayload, Authenticatable {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var role: User.Role
    
    var userID: UUID? {
        UUID(uuidString: subject.value)
    }
    
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
    func token() throws -> UserToken {
        try UserToken(for: self)
    }
}
