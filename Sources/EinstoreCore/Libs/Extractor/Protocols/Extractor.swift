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
    
    /// Date the build was built
    var built: Date? { get }
    
    /// Initializer
    init(file: URL, request: Request) throws
    
    /// Process the file
    func process(teamId: DbIdentifier, on: Request) throws -> Future<Build>
    
}


extension Extractor {
    
    /// Compile an app & it's cluster from parsed data
    func app(platform: Build.Platform, teamId: DbIdentifier, on req: Request) throws -> Future<Build> {
        guard let buildName = appName, let buildIdentifier = appIdentifier else {
            throw ExtractorError.invalidAppContent
        }
        
        return ClusterManager.cluster(for: buildIdentifier, platform: platform, teamId: teamId, on: req).flatMap(to: Build.self) { cluster in
            let attr = try FileManager.default.attributesOfItem(atPath: self.file.path)
            let size = Int(truncating: (attr[FileAttributeKey.size] as? NSNumber) ?? 0)
            let iconDataSize = self.iconData?.count ?? 0
            let sizeTotal = size + iconDataSize

            let build = Build(teamId: teamId, clusterId: (cluster?.id ?? UUID()), name: buildName, identifier: buildIdentifier, version: self.versionLong ?? "0.0", build: self.versionShort ?? "0", platform: platform, built: self.built, size: size, sizeTotal: sizeTotal, minSdk: self.minSdk ?? "1", iconHash: self.iconData?.md5.asUTF8String())
            
            // Compile info (in any is present)
            var info = try? req.query.decode(Build.Info.self)
            if let i = info, i.isEmpty {
                info = nil
            }
            build.info = info
            
            // Save app
            return build.save(on: req).flatMap(to: Build.self) { build in
                guard let cluster = cluster, cluster.id != nil else {
                    let cluster = Cluster(latestBuild: build)
                    return cluster.save(on: req).flatMap(to: Build.self) { cluster in
                        build.clusterId = cluster.id!
                        return build.save(on: req)
                    }
                }
                return build.save(on: req).flatMap(to: Build.self) { build in
                    cluster.latestBuildName = build.name
                    cluster.latestBuildVersion = build.version
                    cluster.latestBuildBuildNo = build.build
                    cluster.latestBuildAdded = build.created
                    cluster.buildCount += 1
                    return cluster.save(on: req).map(to: Build.self) { cluster in
                        return build
                    }
                }
            }
        }
    }
    
    /// Save app files
    func save(_ build: Build, request req: Request) throws -> Future<Void> {
        guard let path = build.appPath?.relativePath else {
            throw ExtractorError.errorSavingFile
        }
        
        let fm = try req.makeFileCore()
        // TODO: These paths need refactor, they have the root added to them in a few places. This should be coming from one method!!!!!
        let tempFile = URL(fileURLWithPath: ApiCoreBase.configuration.storage.local.root)
            .appendingPathComponent(Build.localTempAppFile(on: req).relativePath).path
        return try fm.move(file: tempFile, to: path, on: req).flatMap(to: Void.self) { _ in
            return try build.save(iconData: self.iconData, on: req).map(to: Void.self) { _ in
                try self.cleanUp()
                return Void()
            }
        }
    }
    
    // MARK: Cleaning
    
    /// Clean temp files
    func cleanUp() throws {
        _ = try EinstoreCoreBase.tempFileHandler.delete(url: archive, on: request)
    }
    
}
