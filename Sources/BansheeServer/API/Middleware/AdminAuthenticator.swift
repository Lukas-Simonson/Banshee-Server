import JWT
import Vapor

struct AdminAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let token = try await request.jwt.verify(as: UserToken.self)
        
        guard token.role == .admin else {
            request.logger.warning("User with id: \(token.userID?.uuidString ?? "unknown") and role: \(token.role) tried accessing admin only content.")
            throw AuthError.invalidRole
        }
        
        request.auth.login(token)
    }
}
