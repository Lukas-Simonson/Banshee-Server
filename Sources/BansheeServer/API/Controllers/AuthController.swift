import Vapor

/// Sets up the Auth endpoints
///
/// - `POST /api/auth/setup`: Initial account setup endpoint.
/// - `POST /api/auth/register`: Admin Only, allows creating accounts.
/// - `GET  /api/auth/login`: Returns an auth token based on provided user information.
struct AuthController: RouteCollection {
    
    /// Called to register the routes of the collection.
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        auth.post("setup", use: setup)
        
        auth.grouped(UserToken.authenticator())
            .grouped(UserToken.adminGuardMiddleware())
            .post("register", use: register)
        
        auth.grouped(UserBasicAuthenticator())
            .post("login", use: login)
    }
    
    /// Creates an admin user, can only be used when no admin users exist.
    ///
    /// Body: ``RegisterRequest``
    ///
    /// > Note: The `RegisterRequest.role` property must be `.admin`
    ///
    /// - Returns: `201 Created` status with a ``UserDTO`` body.
    private func setup(req: Request) async throws -> Response {
        try RegisterRequest.validate(content: req)
        let registerRequest = try req.content.decode(RegisterRequest.self)
        
        guard registerRequest.role == .admin
        else { throw Abort(.badRequest, reason: "The /api/auth/setup endpoint can only be used to create admin users.") }
        
        guard try await req.userDAO.adminCount() == 0
        else { throw Abort(.badRequest, reason: "An admin account already exists, please use the /api/auth/register endpoint to create a new user.") }
        
        return try await req.userDAO
            .create(
                email: registerRequest.email,
                username: registerRequest.username,
                name: registerRequest.name,
                passwordHash: req.password.async.hash(registerRequest.password),
                role: registerRequest.role
            )
            .toDTO()
            .encodeResponse(status: .created, for: req)
    }
    
    /// Registers a user, and can only be called by admin users.
    ///
    /// Body: ``RegisterRequest``
    ///
    /// - Returns: `201 Created` status with a ``UserDTO`` body.
    private func register(req: Request) async throws -> Response {
        try RegisterRequest.validate(content: req)
        let registerRequest = try req.content.decode(RegisterRequest.self)
        
        return try await req.userDAO
            .create(
                email: registerRequest.email,
                username: registerRequest.username,
                name: registerRequest.name,
                passwordHash: req.password.async.hash(registerRequest.password),
                role: registerRequest.role
            )
            .toDTO()
            .encodeResponse(status: .created, for: req)
    }
    
    /// Provides a JWT for authentication based on a provided username & password.
    ///
    /// - Returns: A `200 Ok` status code with a ``UserDTO`` body that includes an Authorization Token.
    private func login(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        return try await user.toDTO(with: req.jwt.sign(user.token()))
    }
}

extension AuthController {
    
    /// Request body intended for creating user accounts.
    struct RegisterRequest: Content, Validatable {
        
        /// A unique and valid email address.
        let email: String
        
        /// A unique username consisting of alphanumeric characters.
        let username: String
        
        /// The name of the user.
        let name: String
        
        /// The plaintext password the user will use to authenticate.
        let password: String
        
        /// The role of the created user.
        let role: User.Role
        
        /// The validations used for the request.
        ///
        /// - `email`: Must be a valid email.
        /// - `username`: Must be alphanumeric and at least 2 characters long.
        /// - `name`: Must be at least 2 characters long.
        /// - `password`: Must be at least 8 characters long, contain 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character.
        /// - `role`: Must be either `user` or `admin`
        static func validations(_ validations: inout Validations) {
            validations.add("email", as: String.self, is: .email)
            validations.add("username", as: String.self, is: .alphanumeric && .count(2...))
            validations.add("name", as: String.self, is: .count(2...))
            validations.add(
                "password",
                as: String.self,
                is: .count(8...) && .pattern(#"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&\^])[A-Za-z\d@$!%*?&\^]{8,}$"#)
            )
            validations.add("role", as: String.self, is: .in(["user", "admin"]))
        }
    }
}
