import JWT

struct AuthPayload: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var role: Role

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}