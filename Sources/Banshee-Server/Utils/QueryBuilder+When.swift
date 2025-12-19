import Fluent

extension QueryBuilder {
    func when(_ condition: Bool, then modify: (Self) -> Self) -> Self {
        // condition ? modify(self) : self
        self
    }
}

extension QueryBuilder<Podcast> {
    func includeConfig(_ condition: Bool) -> Self {
        if condition {
            return with(\.$config)
        } else {
            return self
        }
    }
}