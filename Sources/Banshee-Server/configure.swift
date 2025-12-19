import NIOSSL
import Fluent
import FluentPostgresDriver
import JWT
import XMLCoder
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    try await configureXML(app)
    try await configureAuth(app)
    try await configureDatabase(app)

    // register routes
    try routes(app)
}

private func configureXML(_ app: Application) async throws {
    let xmlDecoder = XMLDecoder.rssDecoder()
    
    ContentConfiguration.global.use(decoder: xmlDecoder, for: .xml)
    ContentConfiguration.global.use(decoder: xmlDecoder, for: .init(type: "application", subType: "rss+xml"))
}

private func configureAuth(_ app: Application) async throws {
    await app.jwt.keys.add(hmac: HMACKey(stringLiteral: try getEnvironmentValue("JWT_SECRET")), digestAlgorithm: .sha256)
}

private func configureDatabase(_ app: Application) async throws {
    let configuration = DatabaseConfigurationFactory.postgres(configuration: SQLPostgresConfiguration(
        hostname: try getEnvironmentValue("DATABASE_HOST"),
        port: Int(try getEnvironmentValue("DATABASE_PORT")) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: try getEnvironmentValue("DATABASE_USERNAME"),
        password: try getEnvironmentValue("DATABASE_PASSWORD"),
        database: try getEnvironmentValue("DATABASE_NAME"),
        tls: .prefer(try .init(configuration: .clientDefault)) 
    ))

    app.databases.use(configuration, as: .psql)

    // Migrations
    app.migrations.add(User.Migration.Create())
    app.migrations.add(Podcast.Migration.Create())
    app.migrations.add(Episode.Migration.Create())
}

private func getEnvironmentValue(_ key: String) throws -> String {
    guard let value = Environment.get(key)
    else { throw ConfigurationError.missingEnvironmentValue(key) }
    return value
}

private enum ConfigurationError: Error {
    case missingEnvironmentValue(String)
}