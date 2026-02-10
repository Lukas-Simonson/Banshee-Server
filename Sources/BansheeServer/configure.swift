import Fluent
import FluentSQLiteDriver
import Vapor

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
        app.databases.use(.sqlite(.file("\(metadata)/banshee.sqlite")), as: .sqlite)
        
        // Setup Migrations
        
        // Perform Migrations
        try await app.autoMigrate()
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
            case "STORAGE_PATH": "./AppData/Storage"
            case "METADATA_PATH": "./AppData/Metadata"
            default: throw ConfigError.missingExpectedValue(key: key)
        }
        #else
        throw ConfigError.missingExpectedValue(key: key)
        #endif
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
