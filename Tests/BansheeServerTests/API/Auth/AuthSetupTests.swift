@testable import BansheeServer
import Fakery
import Fluent
import Testing
import VaporTesting

@Suite("/api/auth/setup Tests", .serialized)
struct AuthSetupTests {
    
    @Test
    func `creates user`() async throws {
        try await Application.test { app in
            try await app.testing().test(
                .POST, "api/auth/setup",
                beforeRequest: { req in
                    try req.content.encode(Mock.registration(with: .admin))
                    #expect(try await User.DAO(db: app.db).adminCount() == 0, "Invalid setup for test")
                },
                afterResponse: { response async throws in
                    #expect(response.status == .created)
                    #expect(try await User.DAO(db: app.db).adminCount() == 1)
                }
            )
        }
    }
    
    @Test
    func `denies user role`() async throws {
        try await Application.test { app in
            try await app.testing().test(
                .POST, "api/auth/setup",
                beforeRequest: { req in
                    try req.content.encode(Mock.registration(with: .user))
                    #expect(try await User.DAO(db: app.db).adminCount() == 0, "Invalid setup for test")
                },
                afterResponse: { response async throws in
                    #expect(response.status == .badRequest)
                    #expect(try await User.DAO(db: app.db).adminCount() == 0, "Admin user was created")
                }
            )
        }
    }
    
    @Test
    func `denies creating extra admin accounts`() async throws {
        try await Application.test { app in
            
            try await Mock.user(with: .admin).create(on: app.db)
            #expect(try await User.DAO(db: app.db).adminCount() == 1, "Test requires 1 admin user to be created")
            
            try await app.testing().test(
                .POST, "api/auth/setup",
                beforeRequest: { req in
                    try req.content.encode(Mock.registration(with: .admin))
                },
                afterResponse: { response async throws in
                    #expect(response.status == .badRequest)
                    #expect(try await User.DAO(db: app.db).adminCount() == 1, "Admin user was created")
                }
            )
        }
    }
}

// MARK: Mock Data
extension AuthSetupTests {
    enum Mock {
        static func registration(with role: User.Role) -> AuthController.RegisterRequest {
            AuthController.RegisterRequest(
                email: faker.internet.email(),
                username: faker.internet.username(),
                name: faker.name.name(),
                password: faker.internet.password(),
                role: role
            )
        }
        
        static func user(with role: User.Role) -> User {
            User(
                email: faker.internet.email(),
                username: faker.internet.username(),
                name: faker.name.name(),
                passwordHash: faker.internet.password(),
                role: role
            )
        }
    }
}
