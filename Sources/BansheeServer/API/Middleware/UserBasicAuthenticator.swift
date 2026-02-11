import JWT
import Vapor

struct UserBasicAuthenticator: AsyncBasicAuthenticator {
    func authenticate(basic: BasicAuthorization, for request: Request) async throws {
        guard let user = try await request.userDAO.read(withEmailOrUsername: basic.username),
              try await request.password.async.verify(basic.password, created: user.passwordHash)
        else { throw AuthError.invalidUsernameOrPassword }
        
        request.auth.login(user)
    }
}

