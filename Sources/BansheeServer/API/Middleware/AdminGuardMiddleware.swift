import JWT
import Vapor

extension UserToken {
    
    /// A middleware that prevents non-admin users from accessing content.
    static func adminGuardMiddleware() -> some Middleware {
        AdminGuardMiddleware()
    }
}

private final class AdminGuardMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let token = try request.auth.require(UserToken.self)
        
        guard token.role == .admin else {
            request.logger.warning("User with id: \(token.userID?.uuidString ?? "unknown") and role: \(token.role) tried accessing admin only content.")
            throw AuthError.adminOnlyContent
        }
        
        return try await next.respond(to: request)
    }
}
