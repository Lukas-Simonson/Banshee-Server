import Fluent

extension OptionalChildProperty {
    var isLoaded: Bool { self.value != nil }
    var isNotLoaded: Bool { self.value == nil }
}