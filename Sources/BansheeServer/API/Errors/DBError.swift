import Vapor

enum DBError {
    static func duplicateRow(of type: String) -> Abort {
        Abort(.badRequest, reason: "A matching \(type) has already been created.")
    }
    
    static func noItemFound(_ type: String, with id: UUID) -> Abort {
        Abort(.badRequest, reason: "No \(type) found with an id matching: \(id)")
    }
}
