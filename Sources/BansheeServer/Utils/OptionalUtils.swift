infix operator ?=: AssignmentPrecedence

extension Optional {
    
    /// Sets a non-optional value to an optional value when the provided value exists.
    static func ?=(_ lhs: inout Wrapped, _ rhs: Self) {
        if let rhs {
            lhs = rhs
        }
    }

    /// Sets an optional value to another optional value when the other value exists.
    static func ?=(_ lhs: inout Self, _ rhs: Self) {
        if let rhs {
            lhs = rhs
        }
    }
}

extension Optional {
    
    /// Unwraps the optional value, or throws the provided error.
    func unwrap<E: Error>(or error: @autoclosure () -> E) throws(E) -> Wrapped {
        switch self {
            case .none: throw error()
            case .some(let value): return value
        }
    }
}

