import Vapor

struct AdminAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(AuthPayload.self), user.role == .admin
        else { throw Errors.invalidRole }
        
        return try await next.respond(to: request)
    }

    enum Errors {
        static var invalidRole: Abort { Abort(.unauthorized, reason: "You must be an admin user to access this content") }
    }
}

