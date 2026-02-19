import Fluent

extension Model {
    
    /// Checks if a unique model exists with the provided id.
    ///
    /// > Note: Checks if a unique model exits, will return false if multiple models are provided with the same id.
    ///
    /// - Parameters:
    ///   - id: The id of the model.
    ///   - db: The database to query.
    static func exists(with id: IDValue, on db: any Database) async throws -> Bool {
        try await query(on: db)
            .filter(\._$id == id)
            .count() == 1
    }
    
    /// Checks if a unique model exists with the provided id. Throws the provided error if it does not.
    ///
    /// > Note: Checks if a unique model exists, will return false if multiple models are provided with the same id.
    ///
    /// - Parameters:
    ///   - id: The id of the model.
    ///   - db: The database to query.
    ///   - error: The error to throw when the unique model is not found.
    static func require<E: Error>(oneWith id: IDValue, existsOn db: any Database, or error: E) async throws {
        if try await !exists(with: id, on: db) {
            throw error
        }
    }
}
