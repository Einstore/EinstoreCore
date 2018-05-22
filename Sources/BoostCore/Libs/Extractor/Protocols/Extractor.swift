//
//  Extractor.swift
//  App
//
//  Created by Ondrej Rafaj on 09/12/2017.
//

import Foundation
import Vapor
import ErrorsCore
import ApiCore
import DbCore
import Fluent


/// Extractor error
enum ExtractorError: FrontendError {
    
    /// Unsupported file
    case unsupportedFile
    
    /// Invalid app content
    case invalidAppContent
    
    /// Error saving file
    case errorSavingFile
    
    /// Error code
    public var identifier: String {
        switch self {
        case .unsupportedFile:
            return "boost.extractor.unsupported_file"
        case .invalidAppContent:
            return "boost.extractor.invalid_app_content"
        case .errorSavingFile:
            return "boost.extractor.error_saving_file"
        }
    }
    
    /// HTTP error status code
    public var status: HTTPStatus {
        switch self {
        default:
            return .preconditionFailed
        }
    }
    
    /// Reason for failure
    public var reason: String {
        switch self {
        case .unsupportedFile:
            return "Invalid file type"
        case .invalidAppContent:
            return "Invalid or unsupported app content"
        case .errorSavingFile:
            return "Unable to save app file on the server"
        }
    }
}


/// Extractor protocol
protocol Extractor {
    
    /// Request
    var request: Request { get }
    
    /// File
    var file: URL { get }
    
    /// Archive
    var archive: URL { get }
    
    /// Extracted icon data
    var iconData: Data? { get }
    
    /// Parsed app name
    var appName: String? { get }
    
    /// Parsed app identifier (bundle ID)
    var appIdentifier: String? { get }
    
    /// Short version (build number usually)
    var versionShort: String? { get }
    
    /// Long version (version, usually like 1.2.3)
    var versionLong: String? { get }
    
    /// Initializer
    init(file: URL, request: Request) throws
    
    /// Process the file
    func process(teamId: DbCoreIdentifier, on: Request) throws -> Promise<App>
    
}


extension Extractor {
    
    /// System bin URL
    /// Contains all commandline utilities
    var binUrl: URL {
        let config = DirectoryConfig.detect()
        var url: URL = URL(fileURLWithPath: config.workDir).appendingPathComponent("Resources")
        url.appendPathComponent("bin")
        return url
    }
    
    /// Compile an app & it's cluster from parsed data
    func app(platform: App.Platform, teamId: DbCoreIdentifier, on req: Request) throws -> Future<App> {
        guard let appName = appName, let appIdentifier = appIdentifier else {
            throw ExtractorError.invalidAppContent
        }
        
        return try Cluster.query(on: req).filter(\Cluster.identifier == appIdentifier).filter(\Cluster.platform == platform).first().flatMap(to: App.self) { cluster in
            let app = App(teamId: teamId, clusterId: UUID(), name: appName, identifier: appIdentifier, version: self.versionLong ?? "0.0", build: self.versionShort ?? "0", platform: platform, hasIcon: (self.iconData != nil))
            guard let cluster = cluster, let clusterId = cluster.id else {
                let cluster = Cluster(latestApp: app)
                return cluster.save(on: req).map(to: App.self) { cluster in
                    app.clusterId = cluster.id!
                    return app
                }
            }
            app.clusterId = clusterId
            cluster.latestAppName = app.name
            cluster.latestAppVersion = app.version
            cluster.latestAppBuild = app.build
            cluster.latestAppAdded = app.created
            cluster.appCount += 1
            return cluster.save(on: req).map(to: App.self) { cluster in
                return app
            }
        }
    }
    
    /// Save app into the DB
    func save(_ app: App, request req: Request, _ fileHandler: FileHandler) throws -> Future<Void> {
        var saves: [Future<Void>] = []
        guard let path = app.appPath, let folder = app.targetFolderPath else {
            throw ExtractorError.errorSavingFile
        }
        
        return try Boost.storageFileHandler.createFolderStructure(url: folder, on: req).flatMap(to: Void.self) { _ in
            let tempFile = App.tempAppFile(on: req)
            saves.append(try fileHandler.move(from: tempFile, to: path, on: self.request))
            if let iconData = self.iconData, let path = app.iconPath?.path {
                saves.append(try fileHandler.save(data: iconData, to: path, on: self.request))
            }
            return saves.flatten(on: req).map(to: Void.self) { _ in
                try self.cleanUp()
            }
        }
    }
    
    // MARK: Cleaning
    
    /// Clean temp files
    func cleanUp() throws {
        _ = try Boost.tempFileHandler.delete(url: archive, on: request)
    }
    
}
