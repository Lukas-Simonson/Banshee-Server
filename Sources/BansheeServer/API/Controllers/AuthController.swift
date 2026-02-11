import Vapor

/// Sets up the Auth endpoints
///
/// - `/api/auth/setup`: Initial account setup endpoint.
/// - `/api/auth/register`: Admin Only, allows creating accounts.
/// - `/api/auth/login`: Returns an auth token based on provided user information.
struct AuthController: RouteCollection {
    
    /// Called to register the routes of the collection.
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        auth.post("setup", use: setup)
        
        auth.grouped(AdminAuthenticator())
            .post("register", use: register)
        
        auth.post("login", use: login)
    }
    
    /// Creates an admin user, can only be used when no admin users exist.
    ///
    /// Expects a ``RegisterRequest`` for the request body.
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
        
        let user = try await req.userDAO.create(
            email: registerRequest.email,
            username: registerRequest.username,
            name: registerRequest.name,
            passwordHash: req.password.async.hash(registerRequest.password),
            role: registerRequest.role
        )
        
        return try Response(
            status: .created,
            content: user.toDTO(),
            encoder: req.contentEncoder
        )
    }
    
    /// Registers a user, and can only be called by admin users.
    ///
    /// Expects a ``RegisterRequest`` for the request body.
    ///
    /// - Returns: `201 Created` status with a ``UserDTO`` body.
    private func register(req: Request) async throws -> Response {
        try RegisterRequest.validate(content: req)
        let registerRequest = try req.content.decode(RegisterRequest.self)
        
        let user = try await req.userDAO.create(
            email: registerRequest.email,
            username: registerRequest.username,
            name: registerRequest.name,
            passwordHash: req.password.async.hash(registerRequest.password),
            role: registerRequest.role
        )
        
        return try Response(
            status: .created,
            content: user.toDTO(),
            encoder: req.contentEncoder
        )
    }
    
    /// Provides a JWT for authentication based on a provided username & password.
    ///
    /// Expects a ``SignInRequest`` for the request body.
    ///
    /// - Returns: A `200 Ok` status code with a ``UserDTO`` body that includes an Authorization Token.
    private func login(req: Request) async throws -> Response {
        try SignInRequest.validate(content: req)
        let signInRequest = try req.content.decode(SignInRequest.self)
        
        guard let user = try await req.userDAO.read(withEmailOrUsername: signInRequest.username),
              try await req.password.async.verify(signInRequest.password, created: user.passwordHash)
        else { throw AuthError.invalidUsernameOrPassword }
        
        return try await Response(
            status: .ok,
            content: user.toDTO(with: req.jwt.sign(UserToken(for: user))),
            encoder: req.contentEncoder
        )
    }
}

extension AuthController {
    
    /// Request body intended for use of basic authentication.
    struct SignInRequest: Content, Validatable {
        
        /// The username OR email of the user attempting to sign in.
        let username: String
        
        /// The plaintext password of the user attempting to sign in.
        let password: String
        
        /// The validations used for the request.
        ///
        /// - `username`: Must be either an email or alphanumeric.
        static func validations(_ validations: inout Vapor.Validations) {
            validations.add("username", as: String.self, is: .email || .alphanumeric)
        }
    }
    
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
        /// - `username`: Must be alphanumeric.
        /// - `role`: Must be either `user` or `admin`
        static func validations(_ validations: inout Validations) {
            validations.add("email", as: String.self, is: .email)
            validations.add("username", as: String.self, is: .alphanumeric)
            validations.add("name", as: String.self)
            validations.add("password", as: String.self)
            validations.add("role", as: String.self, is: .in(["user", "admin"]))
        }
    }
}
