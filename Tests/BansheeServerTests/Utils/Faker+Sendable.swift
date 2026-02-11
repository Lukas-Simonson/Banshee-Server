import Fakery

extension Faker: @retroactive @unchecked Sendable {}

let faker = Faker(locale: "en-US")
