import Foundation

@propertyWrapper
struct Nullable<Content: Codable>: Codable {
    
    /// The regular `Optional` value.
    var wrappedValue: Content?
    
    /// If a `nil` value was / should be omitted on decode / encode.
    var isOmitted: Bool
    
    /// If the value was / should be set to `null`.
    var isNull: Bool { !isOmitted && wrappedValue == nil }
    
    var projectedValue: Self {
        get { self }
        set { self = newValue }
    }
    
    init() {
        self.wrappedValue = nil
        self.isOmitted = true
    }
    
    init(wrappedValue: Content?, omitted: Bool) {
        self.wrappedValue = wrappedValue
        self.isOmitted = omitted
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // If we make it here, then a value was included.
        isOmitted = false
        
        // Decode nil or the value.
        wrappedValue = container.decodeNil() ? nil : try container.decode(Content.self)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let wrappedValue { try container.encode(wrappedValue) }
        else if !isOmitted { try container.encodeNil() }
    }
}

extension KeyedDecodingContainer {
    func decode<T: Codable>(_ type: Nullable<T>.Type, forKey key: Key) throws -> Nullable<T> {
        if contains(key) {
            let value = try decodeIfPresent(T.self, forKey: key)
            return Nullable(wrappedValue: value, omitted: false)
        }
        
        return Nullable()
    }
}

extension KeyedEncodingContainer {
    mutating func encode<T: Codable>(_ value: Nullable<T>, forKey key: Key) throws {
        if let value = value.wrappedValue { try encode(value, forKey: key) }
        else if !value.isOmitted { try encodeNil(forKey: key) }
    }
}

extension Nullable: Sendable where Content: Sendable {
    
}
