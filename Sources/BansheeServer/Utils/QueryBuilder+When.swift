import Fluent

extension QueryBuilder {
    /// Allows conditional building of fluent queries.
    func when(_ condition: Bool, then modify: (QueryBuilder<Model>) -> QueryBuilder<Model>) -> QueryBuilder<Model> {
        condition ? modify(self) : self
    }
    
    /// Allows conditional building of fluent queries providing an unwrapped optional value.
    func `let`<T>(_ value: T?, then modify: (T, QueryBuilder<Model>) -> QueryBuilder<Model>) -> QueryBuilder<Model> {
        if let value {
            modify(value, self)
        } else {
            self
        }
    }
}
