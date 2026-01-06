// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Banshee-Server",
    platforms: [
       .macOS(.v14)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        // .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),

        // Fluent driver for sqlite
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🔒 JWT Managment for secure authorization.
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
        // XML Decoding and Encoding using the Codable protocol.
        .package(url: "https://github.com/Lukas-Simonson/Banshee-XMLCoder", branch: "main"),
        // 🌐 Async HTTP client for streaming downloads.
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
        // Queues Driver ontop of Fluent.
        .package(url: "https://github.com/vapor-community/vapor-queues-fluent-driver.git", from: "3.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Banshee-Server",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                // .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "_NIOFileSystem", package: "swift-nio"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "XMLCoder", package: "Banshee-XMLCoder"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "QueuesFluentDriver", package: "vapor-queues-fluent-driver"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "Banshee-ServerTests",
            dependencies: [
                .target(name: "Banshee-Server"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
