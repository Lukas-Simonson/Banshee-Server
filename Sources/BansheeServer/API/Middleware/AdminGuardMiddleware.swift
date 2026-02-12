import JWT
import Vapor

extension UserToken {
    static func adminGuardMiddleware() -> some Middleware {
        AdminGuardMiddleware()
    }
}

private final class AdminGuardMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let token = try request.auth.require(UserToken.self)
        
        guard token.role == .admin else {
            request.logger.warning("User with id: \(token.userID?.uuidString ?? "unknown") and role: \(token.role) tried accessing admin only content.")
            throw AuthError.invalidRole
        }
        
        return try await next.respond(to: request)
    }
}
