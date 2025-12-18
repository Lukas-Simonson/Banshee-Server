import JWT
import Vapor

struct AuthPayload: JWTPayload, Authenticatable {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var role: Role

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}