
extension Optional {
    func unwrap<E: Error>(or error: E) throws(E) -> Self.Wrapped {
        switch self {
            case .none: throw error
            case .some(let value): return value 
        }
    }
}