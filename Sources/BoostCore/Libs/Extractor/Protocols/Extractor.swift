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
import Fluent
import FileCore


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
    
    /// Minimum supported Sdk
    var minSdk: String? { get }
    
    /// Initializer
    init(file: URL, request: Request) throws
    
    /// Process the file
    func process(teamId: DbIdentifier, on: Request) throws -> Future<App>
    
}


extension Extractor {
    
    /// Compile an app & it's cluster from parsed data
    func app(platform: App.Platform, teamId: DbIdentifier, on req: Request) throws -> Future<App> {
        guard let appName = appName, let appIdentifier = appIdentifier else {
            throw ExtractorError.invalidAppContent
        }
        
        return Cluster.query(on: req).filter(\Cluster.identifier == appIdentifier).filter(\Cluster.platform == platform).first().flatMap(to: App.self) { cluster in
            let attr = try FileManager.default.attributesOfItem(atPath: self.file.path)
            // TODO: Fix on linux (file size is not loading)!!!!!!!!!!
            let size = Int(truncating: (attr[FileAttributeKey.size] as? NSNumber) ?? 0)
            let iconDataSize = self.iconData?.count ?? 0
            let sizeTotal = size + iconDataSize
            let app = App(teamId: teamId, clusterId: (cluster?.id ?? UUID()), name: appName, identifier: appIdentifier, version: self.versionLong ?? "0.0", build: self.versionShort ?? "0", platform: platform, size: size, sizeTotal: sizeTotal, minSdk: self.minSdk ?? "", hasIcon: (iconDataSize > 0))
            return app.save(on: req).flatMap(to: App.self) { app in
                guard let cluster = cluster, cluster.id != nil else {
                    let cluster = Cluster(latestApp: app)
                    return cluster.save(on: req).flatMap(to: App.self) { cluster in
                        app.clusterId = cluster.id!
                        return app.save(on: req)
                    }
                }
                return app.save(on: req).flatMap(to: App.self) { app in
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
        }
    }
    
    /// Save app into the DB
    func save(_ app: App, request req: Request) throws -> Future<Void> {
        guard let path = app.appPath?.relativePath else {
            throw ExtractorError.errorSavingFile
        }
        
        let fm = try req.makeFileCore()
        // TODO: These paths need refactor, they have the root added to them in a few places. This should be coming from one method!!!!!
        let tempFile = URL(fileURLWithPath: ApiCoreBase.configuration.storage.local.root)
            .appendingPathComponent(App.localTempAppFile(on: req).relativePath).path
        return try fm.move(file: tempFile, to: path, on: req).flatMap(to: Void.self) { _ in
            if let iconData = self.iconData, let path = app.iconPath?.relativePath, let mime = iconData.imageFileMediaType() {
                return try fm.save(file: iconData, to: path, mime: mime, on: req).map(to: Void.self) { _ in
                    try self.cleanUp()
                    return Void()
                }
            } else {
                try self.cleanUp()
                return req.eventLoop.newSucceededFuture(result: Void())
            }
        }
    }
    
    // MARK: Cleaning
    
    /// Clean temp files
    func cleanUp() throws {
        _ = try BoostCoreBase.tempFileHandler.delete(url: archive, on: request)
    }
    
}
