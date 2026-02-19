import Vapor

enum DBError {
    
    /// `409 Conflict`, resource has already been created.
    ///
    /// - Parameters:
    ///   - type: The type that has already been created.
    static func duplicateRow(of type: String) -> Abort {
        Abort(.conflict, reason: "A matching \(type) has already been created.")
    }
    
    /// `404 Not Found`, no value of the specified type can be found matching the provided id(s).
    ///
    /// - Parameters:
    ///   - type: The type that could not be found.
    ///   - id: A string representation of the id(s) that could not be found.
    ///
    /// > Note: When using this error for multiple ids the `id` property should be a comma separated list of
    /// > values with the types they match. For example: `User: \(userID), Episode: \(episodeID)`.
    static func noItemFound(_ type: String, with id: some CustomStringConvertible) -> Abort {
        Abort(.notFound, reason: "No \(type) found with matching id(s): \(id)")
    }
}
