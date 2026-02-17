import Vapor

enum DBError {
    static func duplicateRow(of type: String) -> Abort {
        Abort(.conflict, reason: "A matching \(type) has already been created.")
    }
    
    static func noItemFound(_ type: String, with id: some CustomStringConvertible) -> Abort {
        Abort(.notFound, reason: "No \(type) found with matching id(s): \(id)")
    }
}
