import NIOSSL
import Fluent
import FluentSQLiteDriver
import JWT
import XMLCoder
import Vapor
import QueuesFluentDriver

// Environment
//  - JWT_SECRET: The secret key to use for JWT.
//  - STORAGE_PATH: Where downloaded files should be stored.
//  - METADATA_PATH: Where metadata files should be stored.

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    try await configureXML(app)
    try await configureAuth(app)
    try await configureDownloads(app)
    try await configureDatabase(app)
    try await configureJobs(app)

    // register routes
    try routes(app)
}

private func configureXML(_ app: Application) async throws {
    let xmlDecoder = XMLDecoder.rssDecoder()

    xmlDecoder.shouldProcessNamespaces = true
    xmlDecoder.namespaceFilteringStrategy = .stripByPrefix(["itunes"])
    
    ContentConfiguration.global.use(decoder: xmlDecoder, for: .xml)
    ContentConfiguration.global.use(decoder: xmlDecoder, for: .init(type: "application", subType: "rss+xml"))
    ContentConfiguration.global.use(decoder: xmlDecoder, for: .init(type: "text", subType: "xml"))
}

private func configureAuth(_ app: Application) async throws {
    await app.jwt.keys.add(hmac: HMACKey(stringLiteral: try getEnvironmentValue("JWT_SECRET")), digestAlgorithm: .sha256)
}

private func configureDownloads(_ app: Application) async throws {
    let path = try getEnvironmentValue("STORAGE_PATH")
    app.downloadManager = DownloadManager(storageBasePath: path, logger: app.logger)
}

private func configureDatabase(_ app: Application) async throws {
//    let configuration = DatabaseConfigurationFactory.postgres(configuration: SQLPostgresConfiguration(
//        hostname: try getEnvironmentValue("DATABASE_HOST"),
//        port: Int(try getEnvironmentValue("DATABASE_PORT")) ?? SQLPostgresConfiguration.ianaPortNumber,
//        username: try getEnvironmentValue("DATABASE_USERNAME"),
//        password: try getEnvironmentValue("DATABASE_PASSWORD"),
//        database: try getEnvironmentValue("DATABASE_NAME"),
//        tls: .prefer(try .init(configuration: .clientDefault)) 
//    ))
//
//    app.databases.use(configuration, as: .psql)

    let metadata = try getEnvironmentValue("METADATA_PATH")
    app.databases.use(.sqlite(.file("\(metadata)/banshee.sqlite")), as: .sqlite)

    // Migrations
    app.migrations.add(User.Migration.Create())
    
    app.migrations.add(Podcast.Migration.Create())
    app.migrations.add(PodcastConfig.Migration.Create())
    app.migrations.add(RSSConfig.Migration.Create())
    
    app.migrations.add(Episode.Migration.Create())
    app.migrations.add(EpisodeConfig.Migration.Create())
    app.migrations.add(AudioConfig.Migration.Create())

    try await app.autoMigrate()
}

private func configureJobs(_ app: Application) async throws {
    // Jobs Migration
    app.migrations.add(JobModelMigration())

    app.queues.use(.fluent(.sqlite))

    app.queues.schedule(RSSFeedJob())
        .hourly()
        .at(0)
}

private func getEnvironmentValue(_ key: String) throws -> String {
    guard let value = Environment.get(key)
    else { throw ConfigurationError.missingEnvironmentValue(key) }
    return value
}

private enum ConfigurationError: Error {
    case missingEnvironmentValue(String)
}
