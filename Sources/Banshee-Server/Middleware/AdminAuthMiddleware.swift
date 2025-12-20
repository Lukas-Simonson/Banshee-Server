import Vapor

struct AdminAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(AuthPayload.self) else { throw Errors.invalidAuth }
        guard user.role == .admin else {
            request.logger.warning("User with id: \(user.subject) and role: \(user.role) tried accessing admin only content.")
            throw Errors.invalidRole
        }

        return try await next.respond(to: request)
    }

    enum Errors {
        static var invalidAuth: Abort { Abort(.unauthorized, reason: "Authentication malformed or missing") }
        static var invalidRole: Abort { Abort(.unauthorized, reason: "You must be an admin user to access this content") }
    }
}

