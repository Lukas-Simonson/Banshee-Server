import Fluent

extension QueryBuilder {
    /// Allows conditional building of fluent queries.
    func when(_ condition: Bool, then modify: (QueryBuilder<Model>) -> QueryBuilder<Model>) -> QueryBuilder<Model> {
        condition ? modify(self) : self
    }
}
