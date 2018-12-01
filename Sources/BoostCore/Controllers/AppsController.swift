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


extension QueryBuilder where Result == App, Database == ApiCoreDatabase {
    
    /// Set filters
    func appFilters(on req: Request) throws -> QueryBuilder<ApiCoreDatabase, Result> {
        let query = try req.query.decode(RequestFilters.self)
        var s: QueryBuilder<ApiCoreDatabase, Result> = try paginate(on: req)
        
        // Basic search
        if let search = req.query.search {
            s = s.group(.or) { or in
                or.filter(\App.name ~~ search)
                or.filter(\App.identifier ~~ search)
                or.filter(\App.info ~~ search)
                or.filter(\App.version ~~ search)
                or.filter(\App.build ~~ search)
            }
        }
        
        // Platform
        if let platform = query.platform {
            s = s.filter(\App.platform == platform)
        }
        
        // Identifier
        if let identifier = query.identifier {
            s = s.filter(\App.identifier ~~ identifier)
        }
        
        return s
    }
    
    /// Make sure we get only apps belonging to the user
    func safeApp(appId: DbIdentifier, teamIds: [DbIdentifier]) throws -> Self {
        return group(.and) { and in
            and.filter(\App.id == appId)
            and.filter(\App.teamId ~~ teamIds)
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
    static func overviewQuery(teams: Teams, on req: Request) throws -> QueryBuilder<ApiCoreDatabase, Cluster.Public> {
        let q = try Cluster.query(on: req).filter(\Cluster.teamId ~~ teams.ids).sort(\Cluster.latestAppAdded, .descending).decode(Cluster.Public.self).paginate(on: req)
        return q
    }
    
    /// Loading routes
    static func boot(router: Router, secure: Router, debug: Router) throws {
        // Get list of apps based on input parameters
        secure.get("apps") { (req) -> Future<Apps> in
            return try req.me.teams().flatMap(to: Apps.self) { teams in
                let q = try App.query(on: req).filter(\App.teamId ~~ teams.ids).sort(\App.created, .descending).appFilters(on: req)
                return q.decode(App.Public.self).all()
            }
        }
        
        // Overview for apps in all teams
        secure.get("apps", "overview") { (req) -> Future<[Cluster.Public]> in
            return try req.me.teams().flatMap(to: [Cluster.Public].self) { teams in
                return try overviewQuery(teams: teams, on: req).all()
            }
        }
        
        // Overview for apps in selected team
        secure.get("teams", DbIdentifier.parameter, "apps", "overview") { (req) -> Future<[Cluster.Public]> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: [Cluster.Public].self) { teams in
                return try overviewQuery(teams: teams, on: req).filter(\Cluster.teamId == teamId).all()
            }
        }
        
        // Team apps info
        secure.get("teams", DbIdentifier.parameter, "apps", "info") { (req) -> Future<App.Info> in
            let teamId = try req.parameters.next(DbIdentifier.self)
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
        secure.get("apps", DbIdentifier.parameter) { (req) -> Future<App.Public> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: App.Public.self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).decode(App.Public.self).first().map(to: App.Public.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    return app
                }
            }
        }
        
        // App icon
        secure.get("apps", DbIdentifier.parameter, "icon") { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: Response.self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().flatMap(to: Response.self) { app in
                    guard let app = app, let path = app.iconPath?.relativePath else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    let fm = try req.makeFileCore()
                    
                    let image = try fm.get(file: path, on: req)
                    return image.flatMap({ data in
                        return try data.asResponse(.ok, contentType: "image/png", to: req)
                    })
                }
            }
        }
        
        // App download history
        secure.get("apps", DbIdentifier.parameter, "history") { (req) -> Future<[Download]> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: [Download].self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).sort(\Download.created, .descending).first().flatMap(to: [Download].self) { app in
                    guard let _ = app, let userId = try req.me.user().id else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    
                    return Download.query(on: req).filter(\Download.appId == appId).filter(\Download.userId == userId).all()
                }
            }
        }
        
        // App download auth
        secure.get("apps", DbIdentifier.parameter, "auth") { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: Response.self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().flatMap(to: Response.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    let key = DownloadKey(appId: appId)
                    let originalToken: String = key.token
                    key.token = try key.token.sha()
                    return key.save(on: req).flatMap(to: Response.self) { key in
                        return DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().flatMap(to: Response.self) { _ in
                            key.token = originalToken
                            return try DownloadKey.Public(app: app, downloadKey: key, request: req).asResponse(.ok, to: req)
                        }
                    }
                }
            }
        }
        
        // App plist
        // Plist documentation: https://help.apple.com/deployment/ios/#/apd11fd167c4
        router.get("apps", DbIdentifier.parameter, "plist", UUID.parameter, String.parameter) { (req) -> Future<Response> in
            let _ = try req.parameters.next(DbIdentifier.self)
            let token = try req.parameters.next(UUID.self).uuidString
            return try DownloadKey.query(on: req).filter(\DownloadKey.token == token.sha()).filter(\DownloadKey.added >= Date().addMinute(n: -15)).first().flatMap(to: Response.self) { key in
                guard let key = key else {
                    return DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().map(to: Response.self) { _ in
                        throw ErrorsCore.HTTPError.notAuthorized
                    }
                }
                return App.query(on: req).filter(\App.id == key.appId).first().map(to: Response.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    guard app.platform == .ios else {
                        throw Error.invalidPlatform
                    }
                    let response = try req.response.basic(status: .ok)
                    response.http.headers = HTTPHeaders([("Content-Type", "application/xml; charset=utf-8")])
                    response.http.body = try HTTPBody(data: AppPlist(app: app, token: token, request: req).asPropertyList())
                    return response
                }
            }
        }
        
        // App file
        router.get("apps", DbIdentifier.parameter, "file", UUID.parameter, String.parameter) { (req) -> Future<Response> in
            let _ = try req.parameters.next(DbIdentifier.self)
            let token = try req.parameters.next(UUID.self).uuidString
            return try DownloadKey.query(on: req).filter(\DownloadKey.token == token.sha()).filter(\DownloadKey.added >= Date().addMinute(n: -15)).first().flatMap(to: Response.self) { key in
                guard let key = key else {
                    return DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().map(to: Response.self) { _ in
                        throw ErrorsCore.HTTPError.notAuthorized
                    }
                }
                return App.query(on: req).filter(\App.id == key.appId).first().flatMap(to: Response.self) { app in
                    guard let app = app, let userId = try req.me.user().id else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    guard App.Platform.is(supported: app.platform) else {
                        throw Error.invalidPlatform
                    }
                    let response = try req.response.basic(status: .ok)
                    response.http.headers = HTTPHeaders([("Content-Type", "\(app.platform.mime)"), ("Content-Disposition", "attachment; filename=\"\(app.name.safeText).\(app.platform.fileExtension)\"")])
                    
                    guard let path = app.appPath?.relativePath else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    
                    // Save an info about the download
                    let download = Download(appId: key.appId, userId: userId)
                    return download.save(on: req).flatMap(to: Response.self) { download in
                        // Serve the file
                        let fm = try req.makeFileCore()
                        return try fm.get(file: path, on: req).map(to: Response.self) { appData in
                            response.http.body = HTTPBody(data: appData)
                            return response
                        }
                    }
                }
            }
        }
        
        func delete(cluster: Cluster?, on req: Request) throws -> Future<Response> {
            guard let cluster = cluster, let teamId = cluster.teamId else {
                throw Error.clusterInconsistency
            }
            return try req.me.verifiedTeam(id: teamId).flatMap(to: Response.self) { team in
                return try cluster.apps.query(on: req).all().flatMap(to: Response.self) { apps in
                    var futures: [Future<Void>] = []
                    try apps.forEach({
                        try futures.append(contentsOf: delete(app: $0, on: req))
                    })
                    
                    return try futures.flatten(on: req).asResponse(to: req)
                }
            }
        }
        
        func delete(app: App, countCluster cluster: Cluster? = nil, on req: Request) throws -> [Future<Void>] {
            var futures: [Future<Void>] = []
            // TODO: Refactor and split following into smaller methods!!
            
            // Handle cluster data
            if let cluster = cluster {
                if cluster.appCount <= 1 {
                    futures.append(cluster.delete(on: req).flatten())
                } else {
                    cluster.appCount -= 1
                    let save = App.query(on: req).sort(\App.created, .descending).first().flatMap(to: Void.self) { app in
                        guard let app = app else {
                            throw Error.clusterInconsistency
                        }
                        return cluster.add(app: app, on: req).flatten()
                    }
                    futures.append(save)
                }
            }
            
            let f = try app.tags.query(on: req).all().flatMap(to: Void.self) { tags in
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
                guard let path = app.targetFolderPath?.relativePath else {
                    // TODO: Report if there was a problem somehow!!
                    return req.future()
                }
                
                let fm = try req.makeFileCore()
                let deleteFuture = try fm.delete(file: path, on: req)
                futures.append(deleteFuture)
                return futures.flatten(on: req)
            }
            futures.append(f)
            
            return futures
        }
        
        // Delete all apps foir platform and identifier
        secure.delete("cluster") { (req) -> Future<Response> in
            guard let identifier = try? req.query.decode(Cluster.Identifier.self) else {
                throw ErrorsCore.HTTPError.missingRequestData
            }
            return Cluster.query(on: req).filter(\Cluster.identifier == identifier.value).filter(\Cluster.platform == identifier.platform).first().flatMap(to: Response.self) { cluster in
                return try delete(cluster: cluster, on: req)
            }
        }
        
        // Delete whole cluster of apps
        secure.delete("cluster", DbIdentifier.parameter) { (req) -> Future<Response> in
            let clusterId = try req.parameters.next(DbIdentifier.self)
            return Cluster.query(on: req).filter(\Cluster.id == clusterId).first().flatMap(to: Response.self) { cluster in
                return try delete(cluster: cluster, on: req)
            }
        }
        
        // Delete app
        secure.delete("apps", DbIdentifier.parameter) { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: Response.self) { teams in
                return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().flatMap(to: Response.self) { app in
                    guard let app = app else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    return Cluster.query(on: req).filter(\Cluster.identifier == app.identifier).filter(\Cluster.platform == app.platform).first().flatMap(to: Response.self) { cluster in
                        guard let cluster = cluster else {
                            throw Error.clusterInconsistency
                        }
                        
                        return try delete(app: app, countCluster: cluster, on: req).flatten(on: req).asResponse(to: req)
                    }
                }
            }
        }
        
        // Upload app from CI with Upload API key
        router.post("apps") { (req) -> Future<Response> in
            guard let token = try? req.query.decode(UploadKey.Token.self) else {
                throw ErrorsCore.HTTPError.missingAuthorizationData
            }
            return try UploadKey.query(on: req).filter(\UploadKey.token == token.value.sha()).first().flatMap(to: Response.self) { uploadToken in
                guard let uploadToken = uploadToken else {
                    throw AuthError.authenticationFailed
                }
                return try req.me.verifiedTeam(id: uploadToken.teamId).flatMap(to: Response.self) { team in
                    return try upload(team: team, on: req)
                }
            }
        }
        
        // Upload app from authenticated session (browser, app, etc ...)
        secure.post("teams", UUID.parameter, "apps") { (req) -> Future<Response> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: Response.self) { (team) -> Future<Response> in
                return try upload(team: team, on: req)
            }
        }
    }
    
}


extension AppsController {
    
    /// Shared upload method
    static func upload(team: Team, on req: Request) throws -> Future<Response> {
        guard let teamId = team.id else {
            throw Team.Error.invalidTeam
        }
        // TODO: Change to copy file when https://github.com/vapor/core/pull/83 is done
        return req.fileData.flatMap(to: Response.self) { (data) -> Future<Response> in
            // TODO: Think of a better way of identifying the iOS/Android apps
            let url = URL(fileURLWithPath: ApiCoreBase.configuration.storage.local.root)
                .appendingPathComponent(App.localTempAppFolder(on: req).relativePath)
            return try BoostCoreBase.tempFileHandler.createFolderStructure(url: url, on: req).flatMap(to: Response.self) { _ in
                let tempFilePath = URL(fileURLWithPath: ApiCoreBase.configuration.storage.local.root)
                    .appendingPathComponent(App.localTempAppFile(on: req).relativePath)
                try data.write(to: tempFilePath)
                
                let output: RunOutput = SwiftShell.run("unzip", "-l", tempFilePath.path)
                
                let platform: App.Platform
                if output.succeeded {
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
                    throw ExtractorError.invalidAppContent
                }
                
                let extractor: Extractor = try BaseExtractor.decoder(file: tempFilePath.path, platform: platform, on: req)
                do {
                    return try extractor.process(teamId: teamId, on: req).flatMap(to: Response.self) { app in
                        return try extractor.save(app, request: req).flatMap(to: Response.self) { (_) -> Future<Response> in
                            return try handleTags(on: req, team: team, app: app).flatMap(to: Response.self) { (_) -> Future<Response> in
                                return try app.asResponse(.created, to: req)
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
    
    /// Handle tags during upload
    static func handleTags(on req: Request, team: Team, app: App) throws -> Future<Void> {
        if req.http.url.query != nil, let query = try? req.query.decode([String: String].self) {
            if let tags = query["tags"]?.split(separator: "|").map({ String($0) }) {
                return try TagsManager.save(tags: tags, for: app, team: team, on: req)
            }
        }
        return req.eventLoop.newSucceededVoidFuture()
    }
    
}
