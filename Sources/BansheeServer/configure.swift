import Fluent
import FluentSQLiteDriver
import JWT
import QueuesFluentDriver
import Vapor
import XMLCoder

/// Configures the application.
///
/// Expects the following environment variables
/// - `JWT_SECRET`: The secret key to use for JWT
/// - `STORAGE_PATH`: A path to a directory where files like podcast downloads should be stored.
/// - `METADATA_PATH`: A path to a directory where metadata files should be stored.
///
/// When working in a debug environment, the following environment variables are recommended. These are also the default when running in `DEBUG`.
/// - `STORAGE_PATH`: ./.AppData/Storage
/// - `METADATA_PATH`: ./.AppData/Metadata
///
/// Extra Environment Variables
/// - `SERVER_NAME`: The name of the server. Defaults to `Banshee`
/// - `MAX_CONCURRENT_DOWNLOADS`: The max number of concurrent downloads that the server will run (default: 3)
/// - `DOWNLOAD_TIMEOUT`: The number of seconds before an episode download is timed-out (default: 3600)
/// - `MAX_DOWNLOAD_REDIRECT`: The max number of redirects an episode download can go through before failing (default: 5)
/// - `RSS_JOB_INTERVAL`: How often, in minutes, a job should be run to check for out of date feeds. (default: 60)
public func configure(_ app: Application) async throws {
    // Configures Application
    try await Configure(app: app)

    // register routes
    try routes(app)
}

struct Configure {
    let app: Application
    
    @discardableResult
    init(app: Application) async throws {
        self.app = app
        
        app.passwords.use(.bcrypt)
        try await database()
        try await downloads()
        try await jobs()
        try await jwt()
        try await xml()
    }
    
    /// Sets up the database connection using SQLite. Including creating and performing migrations.
    private func database() async throws {
        let metadata = try value(for: "METADATA_PATH")
        
        // Create directory if it doesn't exist
        let (exists, isDirectory) = FileManager.default.pathExists(metadata)
        if !exists {
            try FileManager.default.createDirectory(atPath: metadata, withIntermediateDirectories: true)
        } else if !isDirectory {
            throw ConfigError.expectedDirectory(key: "METADATA_PATH")
        }
        
        // Create Database
        if app.environment == .testing {
            app.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)
        } else {
            app.databases.use(.sqlite(.file("\(metadata)/banshee.sqlite")), as: .sqlite)
        }
        
        // Setup Migrations
        app.migrations.add(User.Migration.Create())
        
        app.migrations.add(Podcast.Migration.Create())
        app.migrations.add(RSSFeed.Migration.Create())
        
        app.migrations.add(Episode.Migration.Create())
        app.migrations.add(EpisodeProgress.Migration.Create())
        app.migrations.add(EpisodeDownload.Migration.Create())
        
        // Perform Migrations
        try await app.autoMigrate()
    }
    
    /// Sets up the ``DownloadManager``
    private func downloads() async throws {
        try app.downloadManager = DownloadManager(
            at: value(for: "STORAGE_PATH"),
            client: HTTPClient(
                eventLoopGroup: app.eventLoopGroup,
                configuration: HTTPClient.Configuration(
                    redirectConfiguration: .follow(
                        max: Int(value(for: "MAX_DOWNLOAD_REDIRECT", or: "5")) ?? 5,
                        allowCycles: false
                    ),
                )
            ),
            data: EpisodeDownloadDAO(db: app.db),
            files: FileManager.default,
            downloadTimeoutSeconds: Int64(value(for: "DOWNLOAD_TIMEOUT", or: "3600")) ?? 3600,
            maxConcurrentDownloads: Int(value(for: "MAX_CONCURRENT_DOWNLOADS", or: "3")) ?? 3
        )
    }
    
    private func jobs() async throws {
        let metadata = try value(for: "METADATA_PATH")
        let jobsDB = DatabaseID(string: "jobs_db")
        
        if app.environment == .testing {
            app.databases.use(.sqlite(.memory), as: jobsDB, isDefault: false)
        } else {
            app.databases.use(.sqlite(.file("\(metadata)/banshee_jobs.sqlite")), as: jobsDB, isDefault: false)
        }
        
        app.queues.use(.fluent(jobsDB))
        app.queues.schedule(UpdateFeedJob())
            .every(seconds: 5)
            // .every(minutes: Int(value(for: "RSS_JOB_INTERVAL", or: "60")) ?? 60)
        
        let job = UpdateFeedJob()
        
        try app.queues.startScheduledJobs()
    }
    
    /// Sets up JWT secret.
    private func jwt() async throws {
        await app.jwt.keys.add(hmac: HMACKey(stringLiteral: try value(for: "JWT_SECRET")), digestAlgorithm: .sha256)
    }
    
    /// Sets up XML Decoding for RSS Feeds.
    private func xml() async throws {
        let decoder = XMLDecoder.rss()
        
        ContentConfiguration.global.use(decoder: decoder, for: .xml)
        ContentConfiguration.global.use(decoder: decoder, for: .init(type: "application", subType: "rss+xml"))
        ContentConfiguration.global.use(decoder: decoder, for: .init(type: "text", subType: "xml"))
    }
    
    /// Gets an environment value for a given key, or throws an error.
    ///
    /// > NOTE: When running in `DEBUG`, default values for certain keys are provided.
    private func value(for key: String) throws -> String {
        let value = Environment.get(key)
        if let value { return value }
        
        #if DEBUG
        return switch key {
            case "JWT_SECRET": "super_secure_jwt"
            case "STORAGE_PATH": "./.AppData/Storage"
            case "METADATA_PATH": "./.AppData/Metadata"
            default: throw ConfigError.missingExpectedValue(key: key)
        }
        #else
        throw ConfigError.missingExpectedValue(key: key)
        #endif
    }
    
    /// Gets an environment value for a given key, or return a provided default.
    ///
    /// > NOTE: When running in `DEBUG`
    private func value(for key: String, or defaultValue: String) -> String {
        (try? value(for: key)) ?? defaultValue
    }
    
    private enum ConfigError: LocalizedError {
        case expectedDirectory(key: String)
        case missingExpectedValue(key: String)
        
        var errorDescription: String? {
            switch self {
                case .expectedDirectory(let key):
                    "environment value \(key) expects a directory and received a file path."
                case .missingExpectedValue(let key):
                    "environment value \(key) was missing"
            }
        }
    }
}
