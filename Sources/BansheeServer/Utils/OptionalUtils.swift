infix operator ?=: AssignmentPrecedence

extension Optional {
    static func ?=(_ lhs: inout Wrapped, _ rhs: Self) {
        lhs = rhs ?? lhs
    }

    static func ?=(_ lhs: inout Self, _ rhs: Self) {
        lhs = rhs ?? lhs
    }
}

extension Optional {
    func unwrap<E: Error>(or error: E) throws(E) -> Wrapped {
        switch self {
            case .none: throw error
            case .some(let value): return value
        }
    }
}

