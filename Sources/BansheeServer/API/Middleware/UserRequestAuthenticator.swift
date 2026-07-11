import JWT
import Vapor

struct UserQueryAuthenticator: AsyncRequestAuthenticator {
    func authenticate(request: Request) async throws {
        let token: String
        if let bearer = request.headers.bearerAuthorization {
            token = bearer.token
        } else if let query = try? request.query.get(String.self, at: "token") {
            token = query
        } else {
            return
        }
        
        try await request.auth.login(request.jwt.verify(token, as: UserToken.self))
    }
}
