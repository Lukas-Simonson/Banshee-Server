import JWT
import Vapor

struct UserAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let token = try await request.jwt.verify(as: UserToken.self)
        request.auth.login(token)
    }
}
