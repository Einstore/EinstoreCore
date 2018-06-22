//
//  AppsController.swift
//  ApiCore
//
//  Created by Ondrej Rafaj on 12/12/2017.
//

import Foundation
import Vapor
import ApiCore
import Fluent
import FluentPostgreSQL
import DbCore
import ErrorsCore
import SwiftShell
import SQL
import DatabaseKit
import FileCore


/// Object holding main filters
fileprivate struct RequestFilters: Codable {
    let platform: App.Platform?
    let identifier: String?
}


extension QueryBuilder where Model == App {
    
    /// Set filters
    func appFilters(on req: Request) throws -> Self {
        let query = try req.query.decode(RequestFilters.self)
        var s = try paginate(on: req)
        
        // Basic search
        if let search = req.query.search {
            s = try s.group(.or) { or in
                try or.filter(\App.name ~~ search)
                try or.filter(\App.identifier ~~ search)
                try or.filter(\App.info ~~ search)
                try or.filter(\App.version ~~ search)
                try or.filter(\App.build ~~ search)
            }
        }
        
        // Platform
        if let platform = query.platform {
            s = try s.filter(\App.platform == platform)
        }
        
        // Identifier
        if let identifier = query.identifier {
            s = try s.filter(\App.identifier ~~ identifier)
        }
        
        return s
    }
    
    /// Make sure we get only apps belonging to the user
    func safeApp(appId: DbCoreIdentifier, teamIds: [DbCoreIdentifier]) throws -> Self {
        return try group(.and) { and in
            try and.filter(\App.id == appId)
            try and.filter(\App.teamId ~~ teamIds)
        }
    }
    
}


class AppsController: Controller {
    
    /// Error
    enum Error: FrontendError {
        
        /// Invalid platform
        case invalidPlatform
        
        /// App cluster inconsistent
        case clusterInconsistency
        
        /// Error code
        var identifier: String {
            switch self {
            case .invalidPlatform:
                return "boost.app.invalid_platform"
            case .clusterInconsistency:
                return "boost.app.cluster_inconsistency"
            }
        }
        
        /// Error reason
        var reason: String {
            switch self {
            case .invalidPlatform:
                return "Unsupported platform"
            case .clusterInconsistency:
                return "Missing or corrupted app cluster data"
            }
        }
        
        /// Error HTTP status code
        var status: HTTPStatus {
            return .conflict
        }
        
    }
    
    /// Overview app query
    static func overviewQuery(teams: Teams, on req: Request) throws -> QueryBuilder<Cluster, Cluster.Public> {
        let q = try Cluster.query(on: req).filter(\Cluster.teamId ~~ teams.ids).decode(Cluster.Public.self).paginate(on: req)
        return q
    }
    
    /// Loading routes
    static func boot(router: Router) throws {
        // Get list of apps based on input parameters
        router.get("apps") { (req) -> Future<Apps> in
            return try req.me.teams().flatMap(to: Apps.self) { teams in
                return try App.query(on: req).filter(\App.teamId ~~ teams.ids).sort(\App.created, QuerySortDirection.descending).appFilters(on: req).all()
            }
        }
        
        // Overview for apps in all teams
        router.get("apps", "overview") { (req) -> Future<[Cluster.Public]> in
            return try req.me.teams().flatMap(to: [Cluster.Public].self) { teams in
                return try overviewQuery(teams: teams, on: req).all()
            }
        }
        
        // Overview for apps in selected team
        router.get("teams", DbCoreIdentifier.parameter, "apps", "overview") { (req) -> Future<[Cluster.Public]> in
            let teamId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.me.teams().flatMap(to: [Cluster.Public].self) { teams in
                return try overviewQuery(teams: teams, on: req).filter(\Cluster.teamId == teamId).all()
            }
        }
        
        // Team apps info
        router.get("teams", DbCoreIdentifier.parameter, "apps", "info") { (req) -> Future<App.Info> in
            let teamId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.me.teams().flatMap(to: App.Info.self) { teams in
                return try overviewQuery(teams: teams, on: req).filter(\Cluster.teamId == teamId).all().map(to: App.Info.self) { apps in
                    var builds: Int = 0
                    apps.forEach({ item in
                        builds += item.appCount
                    })
                    let info = App.Info(teamId: teamId, apps: apps.count, builds: builds)
                    return info
                }
            }
        }
        
        // App detail
        router.get("apps", DbCoreIdentifier.parameter) { (req) -> Future<App> in
            let appId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.me.teams().flatMap(to: App.self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().map(to: App.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    return app
                }
            }
        }
        
        // App download auth
        router.get("apps", DbCoreIdentifier.parameter, "auth") { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.me.teams().flatMap(to: Response.self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().flatMap(to: Response.self) { app in
                    guard let app = app, let appId = app.id else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    let key = DownloadKey(appId: appId)
                    let originalToken: String = key.token
                    key.token = try key.token.passwordHash(req)
                    return key.save(on: req).flatMap(to: Response.self) { key in
                        return try DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().flatMap(to: Response.self) { _ in
                            key.token = originalToken
                            return try DownloadKey.Public(downloadKey: key, request: req).asResponse(.ok, to: req)
                        }
                    }
                }
            }
        }
        
        // App plist
        router.get("apps", "plist") { (req) -> Future<Response> in
            let token = try req.query.decode(DownloadKey.Token.self)
            return try DownloadKey.query(on: req).filter(\DownloadKey.token == token.token).filter(\DownloadKey.added >= Date().addMinute(n: -15)).first().flatMap(to: Response.self) { key in
                guard let key = key else {
                    return try DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().map(to: Response.self) { _ in
                        throw ErrorsCore.HTTPError.notAuthorized
                    }
                }
                return try App.query(on: req).filter(\App.id == key.appId).first().map(to: Response.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    guard app.platform == .ios else {
                        throw Error.invalidPlatform
                    }
                    let response = try req.response.basic(status: .ok)
                    response.http.headers = HTTPHeaders([("Content-Type", "application/xml; charset=utf-8")])
                    response.http.body = try HTTPBody(data: AppPlist(app: app, request: req).asPropertyList())
                    return response
                }
            }
        }
        
        // App file
        router.get("apps", "file") { (req) -> Future<Response> in
            let token = try req.query.decode(DownloadKey.Token.self)
            return try DownloadKey.query(on: req).filter(\DownloadKey.token == token.token).filter(\DownloadKey.added >= Date().addMinute(n: -15)).first().flatMap(to: Response.self) { key in
                guard let key = key else {
                    return try DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().map(to: Response.self) { _ in
                        throw ErrorsCore.HTTPError.notAuthorized
                    }
                }
                return try App.query(on: req).filter(\App.id == key.appId).first().map(to: Response.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    guard app.platform == .ios else {
                        throw Error.invalidPlatform
                    }
                    let response = try req.response.basic(status: .ok)
                    response.http.headers = HTTPHeaders([("Content-Type", "\(app.platform.mime)"), ("Content-Disposition", "attachment; filename=\"\(app.name.safeText).\(app.platform.fileExtension)\"")])
                    let appData = try Data(contentsOf: app.appPath!, options: [])
                    response.http.body = HTTPBody(data: appData)
                    return response
                }
            }
        }
        
        // Tags for app
        router.get("apps", DbCoreIdentifier.parameter, "tags") { (req) -> Future<Tags> in
            let appId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.me.teams().flatMap(to: Tags.self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().flatMap(to: Tags.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    return try app.tags.query(on: req).all()
                }
            }
        }
        
        // Delete app
        router.delete("apps", DbCoreIdentifier.parameter) { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.me.teams().flatMap(to: Response.self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().flatMap(to: Response.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    return try Cluster.query(on: req).filter(\Cluster.identifier == app.identifier).filter(\Cluster.platform == app.platform).first().flatMap(to: Response.self) { cluster in
                        guard let cluster = cluster else {
                            throw Error.clusterInconsistency
                        }
                        return try app.tags.query(on: req).all().flatMap(to: Response.self) { tags in
                            var futures: [Future<Void>] = []
                            // TODO: Refactor and split following into smaller methods!!
                            
                            // Handle cluster data
                            if cluster.appCount <= 1 {
                                futures.append(cluster.delete(on: req).flatten())
                            } else {
                                cluster.appCount -= 1
                                let save = try App.query(on: req).sort(\App.created, .descending).first().flatMap(to: Void.self) { app in
                                    guard let app = app else {
                                        throw Error.clusterInconsistency
                                    }
                                    cluster.latestAppName = app.name
                                    cluster.latestAppVersion = app.version
                                    cluster.latestAppBuild = app.build
                                    cluster.latestAppAdded = app.created
                                    return cluster.save(on: req).flatten()
                                }
                                futures.append(save)
                            }
                            
                            // Delete all tags
                            try tags.forEach({ tag in
                                let tagFuture = try tag.apps.query(on: req).count().flatMap(to: Void.self) { count in
                                    if count <= 1 {
                                        return tag.delete(on: req).flatten()
                                    }
                                    else {
                                        return app.tags.detach(tag, on: req).flatten()
                                    }
                                }
                                futures.append(tagFuture)
                            })
                            
                            // Delete app
                            futures.append(app.delete(on: req).flatten())
                            
                            // Delete all files
                            guard let path = app.targetFolderPath?.path else {
                                return try req.eventLoop.newSucceededFuture(result: req.response.internalServerError(message: "Unable to delete files"))
                            }
                            
                            let fm = try req.makeFileCore()
                            let deleteFuture = try fm.delete(file: path, on: req)
                            futures.append(deleteFuture)
                            return try futures.flatten(on: req).asResponse(to: req)
                        }
                    }
                }
            }
        }
        
        // Upload app from CI with Upload API key
        router.post("apps") { (req) -> Future<Response> in
            guard let token = try? req.query.decode(UploadKey.Token.self) else {
                throw ErrorsCore.HTTPError.missingAuthorizationData
            }
            return try UploadKey.query(on: req).filter(\.token == token.token).first().flatMap(to: Response.self) { (uploadToken) -> Future<Response> in
                guard let uploadToken = uploadToken else {
                    throw AuthError.authenticationFailed
                }
                
                return upload(teamId: uploadToken.teamId, on: req)
            }
        }
        
        // Upload app from authenticated session (browser, app, etc ...)
        router.post("teams", UUID.parameter, "apps") { (req) -> Future<Response> in
            let teamId = try req.parameters.next(DbCoreIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: Response.self) { (team) -> Future<Response> in
                return upload(teamId: teamId, on: req)
            }
        }
    }
    
}


extension AppsController {
    
    /// Shared upload method
    static func upload(teamId: DbCoreIdentifier, on req: Request) -> Future<Response> {
        return App.query(on: req).first().flatMap(to: Response.self) { (app) -> Future<Response> in
            // TODO: Change to copy file when https://github.com/vapor/core/pull/83 is done
            return req.fileData.flatMap(to: Response.self) { (data) -> Future<Response> in
                // TODO: -------- REFACTOR ---------
                return try BoostCoreBase.tempFileHandler.createFolderStructure(url: App.tempAppFolder(on: req), on: req).flatMap(to: Response.self) { _ in
                    let tempFilePath = App.tempAppFile(on: req)
                    try data.write(to: tempFilePath)
                    
                    let output: RunOutput = SwiftShell.run("unzip", "-l", tempFilePath.path)
                    
                    let platform: App.Platform
                    if output.succeeded {
                        print(output.stdout)
                        
                        if output.stdout.contains("Payload/") {
                            platform = .ios
                        }
                        else if output.stdout.contains("AndroidManifest.xml") {
                            platform = .android
                        }
                        else {
                            throw ExtractorError.invalidAppContent
                        }
                    }
                    else {
                        print(output.stderror)
                        throw ExtractorError.invalidAppContent
                    }
                    // */ -------- REFACTOR END (or just carry on and make me better!) ---------
                    
                    let extractor: Extractor = try BaseExtractor.decoder(file: tempFilePath.path, platform: platform, on: req)
                    do {
                        let promise: Promise<App> = try extractor.process(teamId: teamId, on: req)
                        return promise.futureResult.flatMap(to: Response.self) { (app) -> Future<Response> in
                            return app.save(on: req).flatMap(to: Response.self) { (app) -> Future<Response> in
                                return try extractor.save(app, request: req).flatMap(to: Response.self) { (_) -> Future<Response> in
                                    return try handleTags(on: req, app: app).flatMap(to: Response.self) { (_) -> Future<Response> in
                                        return try app.asResponse(.created, to: req)
                                    }
                                }
                            }
                        }
                    } catch {
                        try extractor.cleanUp()
                        throw error
                    }
                }
            }
        }
    }
    
    /// Handle tags during upload
    static func handleTags(on req: Request, app: App) throws -> Future<Void> {
        if req.http.url.query != nil, let query = try? req.query.decode([String: String].self) {
            if let tags = query["tags"]?.split(separator: "|") {
                var futures: [Future<Void>] = []
                try tags.forEach { (tagSubstring) in
                    let tag = String(tagSubstring)
                    let future = try Tag.query(on: req).filter(\Tag.identifier == tag).first().flatMap(to: Void.self) { (tagObject) -> Future<Void> in
                        guard let tagObject = tagObject else {
                            let t = Tag(id: nil, name: tag, identifier: tag.safeText)
                            return t.save(on: req).flatMap(to: Void.self, { (tag) -> Future<Void> in
                                return app.tags.attach(tag, on: req).flatten()
                            })
                        }
                        return app.tags.attach(tagObject, on: req).flatten()
                    }
                    futures.append(future)
                }
                return futures.flatten(on: req)
            }
        }
        return req.eventLoop.newSucceededVoidFuture()
    }
    
}
