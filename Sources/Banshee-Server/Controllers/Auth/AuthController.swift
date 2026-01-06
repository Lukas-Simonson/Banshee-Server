import Fluent
import JWT
import Vapor

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.group("auth") { auth in
            routes.post("setup", use: setup)

            routes.group(UserAuthenticator()) { auth in
                routes.post("login", use: login)

                routes.group(AdminAuthMiddleware()) { auth in
                    auth.post("register", use: register)
                }
            }
        }
    }

    private func setup(req: Request) async throws -> UserDTO {
        let registration = try req.content.decode(RegistrationRequest.self)

        guard try await User.query(on: req.db)
            .filter(\.$role == .admin)
            .count() == 0
        else { throw Errors.adminAlreadyCreated }

        guard registration.role == .admin
        else { throw Errors.invalidSetupRequest }

        let user = User(
            username: registration.username,
            passwordHash: try Bcrypt.hash(registration.password),
            role: .admin
        )

        try await user.save(on: req.db)

        let payload = AuthPayload(
            subject: SubjectClaim(value: user.id!.uuidString),
            expiration: ExpirationClaim(value: .distantFuture),
            role: .admin
        )

        return try await UserDTO(
            from: user,
            with: req.jwt.sign(payload)
        )
    }

    private func register(req: Request) async throws -> UserDTO {
        let registration = try req.content.decode(RegistrationRequest.self)

        let user = User(
            username: registration.username, 
            passwordHash: try Bcrypt.hash(registration.password), 
            role: registration.role
        )

        try await user.save(on: req.db)

        let payload = AuthPayload(
            subject: SubjectClaim(value: user.id!.uuidString),
            expiration: ExpirationClaim(value: .distantFuture),
            role: user.role
        )

        return try await UserDTO(
            from: user,
            with: req.jwt.sign(payload)
        )
    }

    private func login(req: Request) async throws -> UserDTO {
        let authRequest = try req.content.decode(AuthRequest.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$username == authRequest.username)
            .first(),
            try Bcrypt.verify(authRequest.password, created: user.password)
        else { throw Errors.invalidCredentials }

        let payload = AuthPayload(
            subject: SubjectClaim(value: user.id!.uuidString),
            // TODO: Setup valid expiration.
            expiration: .init(value: .distantFuture), 
            role: user.role
        )

        return try await UserDTO(
            from: user,
            with: req.jwt.sign(payload)
        )
    }
}

extension AuthController {
    enum Errors {
        static var adminAlreadyCreated: Abort { Abort(.badRequest, reason: "An admin account already exists, please use the /api/auth/register endpoint") }
        static var invalidSetupRequest: Abort { Abort(.badRequest, reason: "The /api/auth/setup endpoint can only be used to create admin users") }
        static var invalidCredentials: Abort { Abort(.unauthorized, reason: "Invalid username or password provided") }
    }
}

extension AuthController {

    struct RegistrationRequest: Content {
        let username: String
        let password: String
        let role: Role
    }

    struct AuthRequest: Content {
        let username: String
        let password: String
    }
}
