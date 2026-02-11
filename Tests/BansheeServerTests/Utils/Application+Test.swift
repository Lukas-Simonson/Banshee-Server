@testable import BansheeServer
import Vapor

extension Application {
    static func test(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        
        do {
            try await configure(app)
            try await test(app)
            try await app.autoRevert()
            try await app.asyncShutdown()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
    }
}
