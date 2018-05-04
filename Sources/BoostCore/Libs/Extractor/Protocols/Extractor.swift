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


enum ExtractorError: FrontendError {
    case unsupportedFile
    case invalidAppContent
    case errorSavingFile
    
    public var code: String {
        return "app_error"
    }
    
    public var status: HTTPStatus {
        switch self {
        default:
            return .preconditionFailed
        }
    }
    
    public var description: String {
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


protocol Extractor {
    
    var request: Request { get }
    
    var file: URL { get }
    var archive: URL { get }
    
    var iconData: Data? { get }
    var appName: String? { get }
    var appIdentifier: String? { get }
    var versionShort: String? { get }
    var versionLong: String? { get }
    
    init(file: URL, request: Request) throws
    func process(teamId: DbCoreIdentifier, on: Request) throws -> Promise<App>
    
}


extension Extractor {
    
    var binUrl: URL {
        let config = DirectoryConfig.detect()
        var url: URL = URL(fileURLWithPath: config.workDir).appendingPathComponent("Resources")
        url.appendPathComponent("bin")
        return url
    }
    
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
    
    func cleanUp() throws {
        _ = try Boost.tempFileHandler.delete(url: archive, on: request)
    }
    
}
