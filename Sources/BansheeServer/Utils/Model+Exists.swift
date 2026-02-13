import Fluent

extension Model {
    static func exists(with id: IDValue, on db: any Database) async throws -> Bool {
        try await query(on: db)
            .filter(\._$id == id)
            .count() == 1
    }
}
