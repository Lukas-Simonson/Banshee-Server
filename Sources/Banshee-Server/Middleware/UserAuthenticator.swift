import JWT
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let payload = try await request.jwt.verify(as: AuthPayload.self)
        request.auth.login(payload)
    }
}
