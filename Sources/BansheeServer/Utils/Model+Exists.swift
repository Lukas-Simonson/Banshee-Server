import Fluent

extension Model {
    static func exists(with id: IDValue, on db: any Database) async throws -> Bool {
        try await query(on: db)
            .filter(\._$id == id)
            .count() == 1
    }
    
    static func require<E: Error>(oneWith id: IDValue, existsOn db: any Database, or error: E) async throws {
        if try await !exists(with: id, on: db) {
            throw error
        }
    }
}
