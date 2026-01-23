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

// Debug Environment Recommendations
//  These paths will be ignored by git.
//  - STORAGE_PATH: ./.AppData/Storage
//  - METADATA_PATH: ./.AppData/Metadata

public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Base Configuration
    try await Configure(app: app)

    // register routes
    try routes(app)
}

struct Configure {
    let app: Application
    
    @discardableResult
    init(app: Application) async throws {
        self.app = app
        
        try await xml()
        try await auth()
        try await downloads()
        try await database()
        try await jobs()
    }
    
    private func xml() async throws {
        let xmlDecoder = XMLDecoder.rssDecoder()

        xmlDecoder.shouldProcessNamespaces = true
        xmlDecoder.namespaceFilteringStrategy = .stripByPrefix(["itunes"])
        
        ContentConfiguration.global.use(decoder: xmlDecoder, for: .xml)
        ContentConfiguration.global.use(decoder: xmlDecoder, for: .init(type: "application", subType: "rss+xml"))
        ContentConfiguration.global.use(decoder: xmlDecoder, for: .init(type: "text", subType: "xml"))
    }
    
    private func auth() async throws {
        await app.jwt.keys.add(hmac: HMACKey(stringLiteral: try environmentValue("JWT_SECRET")), digestAlgorithm: .sha256)
    }
    
    private func downloads() async throws {
        let path = try environmentValue("STORAGE_PATH")
        app.downloadManager = DownloadManager(storageBasePath: path, logger: app.logger)
    }
    
    private func database() async throws {
        let metadata = try environmentValue("METADATA_PATH")
        
        // Create the directory if it doesn't exist
        let (doesExist, isDirectory) = FileManager.default.pathExists(metadata)
        if !doesExist {
            try FileManager.default.createDirectory(atPath: metadata, withIntermediateDirectories: true)
        } else if !isDirectory {
            throw ConfigError.metadataPathNotADirectory
        }
        
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
    
    private func jobs() async throws {
        app.migrations.add(JobModelMigration())

        app.queues.use(.fluent(.sqlite))

        app.queues.schedule(RSSFeedJob())
            .hourly()
            .at(0)
        
        try app.queues.startScheduledJobs()
    }
    
    private func environmentValue(_ key: String) throws -> String {
        guard let value = Environment.get(key)
        else { throw ConfigError.missingEnvironmentValue(key) }
        return value
    }
    
    private enum ConfigError: Error {
        case metadataPathNotADirectory
        case missingEnvironmentValue(String)
    }
}
