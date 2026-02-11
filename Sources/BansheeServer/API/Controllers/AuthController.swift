import Vapor

/// Setups the Auth endpoints
///
/// - `/auth/setup`: Initial account setup endpoint.
/// - `/auth/login`: Returns an auth token based on provided user information.
/// - `/auth/register`: Admin Only, allows creating accounts.
struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        auth.grouped(User.authenticator())
            .post("login", use: login)
    }
    
    private func login(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        let token = try UserToken(for: user)
        
        return try await Response(
            status: .ok,
            content: user.toDTO(with: req.jwt.sign(token)),
            encoder: req.contentEncoder
        )
    }
}
