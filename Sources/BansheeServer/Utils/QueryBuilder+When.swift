import Fluent

extension QueryBuilder {
    func when(_ condition: Bool, then modify: (QueryBuilder<Model>) -> QueryBuilder<Model>) -> QueryBuilder<Model> {
        condition ? modify(self) : self
    }
}
