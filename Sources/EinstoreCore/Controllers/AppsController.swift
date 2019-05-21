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
import FileCore


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
    
    /// Loading routes
    static func boot(router: Router, secure: Router, debug: Router) throws {
        @discardableResult func filter<M, DB>(q: inout QueryBuilder<M, DB>, tags: [DbIdentifier]) -> QueryBuilder<M, DB> {
            return q
        }
        
        // Get list of builds based on input parameters
        secure.get("builds") { (req) -> Future<Builds> in
            return try AppsManager.builds(on: req)
        }
        
        // Get a cluster
        secure.get("apps", DbIdentifier.parameter) { (req) -> Future<Cluster> in
            let clusterId = try req.parameters.next(DbIdentifier.self)
            return try AppsManager.cluster(id: clusterId, on: req)
        }
        
        // Get list of builds for a cluster
        secure.get("apps", DbIdentifier.parameter, "builds") { (req) -> Future<Builds> in
            let clusterId = try req.parameters.next(DbIdentifier.self)
            return try AppsManager.builds(clusterId: clusterId, on: req)
        }
        
        // Overview for apps in all teams
        secure.get("apps") { (req) -> Future<[Cluster.Public]> in
            return try req.me.teams().flatMap(to: [Cluster.Public].self) { teams in
                return try AppsManager.overviewQuery(teams: teams, on: req).all()
            }
        }
        
        // Overview for apps in selected team
        secure.get("teams", DbIdentifier.parameter, "apps") { (req) -> Future<[Cluster.Public]> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: [Cluster.Public].self) { teams in
                return try AppsManager.overviewQuery(teams: teams, on: req).filter(\Cluster.teamId == teamId).all()
            }
        }
        
        // Team apps info
        secure.get("teams", DbIdentifier.parameter, "apps", "info") { (req) -> Future<Build.Overview> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: Build.Overview.self) { teams in
                return try AppsManager.overviewQuery(teams: teams, on: req).filter(\Cluster.teamId == teamId).all().map(to: Build.Overview.self) { apps in
                    var builds: Int = 0
                    apps.forEach({ item in
                        builds += item.buildCount
                    })
                    let info = Build.Overview(teamId: teamId, apps: apps.count, builds: builds)
                    return info
                }
            }
        }
        
        // Build detail
        secure.get("builds", DbIdentifier.parameter) { (req) -> Future<Build.Public> in
            let buildId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: Build.Public.self) { teams in
                return try Build.query(on: req).safeBuild(id: buildId, teamIds: teams.ids).decode(Build.Public.self).first().map(to: Build.Public.self) { build in
                    guard let build = build else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    return build
                }
            }
        }
        
        // Build icon
        secure.get("builds", DbIdentifier.parameter, "icon") { (req) -> Future<Response> in
            let buildId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: Response.self) { teams in
                return try Build.query(on: req).safeBuild(id: buildId, teamIds: teams.ids).first().flatMap(to: Response.self) { build in
                    guard let build = build, let path = build.iconPath?.relativePath, build.hasIcon else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    let fm = try req.makeFileCore()
                    if fm.isRemote, let url = try build.iconUrl(on: req) { // External file service
                        let res = req.redirect(to: url.absoluteString, type: .permanent)
                        return req.eventLoop.newSucceededFuture(result: res)
                    } else { // Local file store
                        let image = try fm.get(file: path, on: req)
                        return image.flatMap() { data in
                            guard data.count > 0 else {
                                throw ErrorsCore.HTTPError.notFound
                            }
                            return try data.asResponse(.ok, contentType: "image/png", to: req)
                        }
                    }
                }
            }
        }
        
        // Build download history
        secure.get("builds", DbIdentifier.parameter, "history") { (req) -> Future<[Download]> in
            let buildId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: [Download].self) { teams in
                return try Build.query(on: req).safeBuild(id: buildId, teamIds: teams.ids).first().flatMap(to: [Download].self) { build in
                    guard let _ = build, let userId = try req.me.user().id else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    
                    return Download.query(on: req).filter(\Download.buildId == buildId).filter(\Download.userId == userId).sort(\Download.created, .descending).all()
                }
            }
        }
        
        // Build download auth
        secure.get("builds", DbIdentifier.parameter, "auth") { (req) -> Future<Response> in
            guard let userId = try req.me.user().id else {
                throw ErrorsCore.HTTPError.notAuthorized
            }
            let buildId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: Response.self) { teams in
                return try Build.query(on: req).safeBuild(id: buildId, teamIds: teams.ids).first().flatMap(to: Response.self) { build in
                    guard let build = build else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    let key = DownloadKey(buildId: buildId, userId: userId)
                    let originalToken: String = key.token
                    key.token = try key.token.sha()
                    return key.save(on: req).flatMap(to: Response.self) { key in
                        return DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().flatMap(to: Response.self) { _ in
                            key.token = originalToken
                            return try DownloadKey.Public(build: build, downloadKey: key, request: req).asResponse(.ok, to: req)
                        }
                    }
                }
            }
        }
        
        // Build plist
        // Plist documentation: https://help.apple.com/deployment/ios/#/apd11fd167c4
        router.get("builds", UUID.parameter, "plist", UUID.parameter, String.parameter) { (req) -> Future<Response> in
            let _ = try req.parameters.next(UUID.self)
            let token = try req.parameters.next(UUID.self).uuidString
            return try DownloadKey.query(on: req).filter(\DownloadKey.token == token.sha()).filter(\DownloadKey.added >= Date().addMinute(n: -15)).first().flatMap(to: Response.self) { key in
                guard let key = key else {
                    return DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().map(to: Response.self) { _ in
                        throw ErrorsCore.HTTPError.notAuthorized
                    }
                }
                return Build.query(on: req).filter(\Build.id == key.buildId).first().map(to: Response.self) { build in
                    guard let build = build else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    guard build.platform == .ios else {
                        throw Error.invalidPlatform
                    }
                    let response = try req.response.basic(status: .ok)
                    response.http.headers = HTTPHeaders([("Content-Type", "text/xml; charset=utf-8")]) // text/xml (not application/xml) is neccessary for the iOS deployment to work
                    response.http.body = try HTTPBody(data: BuildPlist(build: build, token: token, request: req).asPropertyList())
                    return response
                }
            }
        }
        
        // Build file
        router.get("builds", DbIdentifier.parameter, "file", UUID.parameter, String.parameter) { (req) -> Future<Response> in
            let _ = try req.parameters.next(DbIdentifier.self)
            let token = try req.parameters.next(UUID.self).uuidString
            return try DownloadKey.query(on: req).filter(\DownloadKey.token == token.sha()).filter(\DownloadKey.added >= Date().addMinute(n: -15)).first().flatMap(to: Response.self) { key in
                guard let key = key else {
                    return DownloadKey.query(on: req).filter(\DownloadKey.added < Date().addMinute(n: -15)).delete().map(to: Response.self) { _ in
                        throw ErrorsCore.HTTPError.notAuthorized
                    }
                }
                return Build.query(on: req).filter(\Build.id == key.buildId).first().flatMap(to: Response.self) { build in
                    guard let build = build, let path = build.appPath?.relativePath else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    guard Build.Platform.is(supported: build.platform) else {
                        throw Error.invalidPlatform
                    }
                    let response = try req.response.basic(status: .ok)
                    response.http.headers = HTTPHeaders([("Content-Type", "\(build.platform.mime)"), ("Content-Disposition", "attachment; filename=\"\(build.name.safeText).\(build.platform.fileExtension)\"")])
                    
                    // Save an info about the download
                    let download = Download(buildId: key.buildId, userId: key.userId)
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
        
        // Delete a whole cluster of apps
        secure.delete("apps", DbIdentifier.parameter) { (req) -> Future<Response> in
            let clusterId = try req.parameters.next(DbIdentifier.self)
            return Cluster.query(on: req).filter(\Cluster.id == clusterId).first().flatMap(to: Response.self) { cluster in
                return try AppsManager.delete(cluster: cluster, on: req)
            }
        }
        
        // Delete a build
        secure.delete("builds", DbIdentifier.parameter) { (req) -> Future<Response> in
            let buildId = try req.parameters.next(DbIdentifier.self)
            return try req.me.teams().flatMap(to: Response.self) { teams in
                return try Build.query(on: req).safeBuild(id: buildId, teamIds: teams.ids).first().flatMap(to: Response.self) { build in
                    guard let build = build else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    return Cluster.query(on: req).filter(\Cluster.identifier == build.identifier).filter(\Cluster.platform == build.platform).first().flatMap(to: Response.self) { cluster in
                        guard let cluster = cluster else {
                            throw Error.clusterInconsistency
                        }
                        
                        return try AppsManager.delete(build: build, countCluster: cluster, on: req).flatten(on: req).asResponse(to: req)
                    }
                }
            }
        }
        
        // Upload a build from CI with Upload API key
        router.post("builds") { (req) -> Future<Response> in
            guard let token = try? req.query.decode(ApiKey.Token.self) else {
                throw ErrorsCore.HTTPError.missingAuthorizationData
            }
            return try ApiKey.query(on: req).filter(\ApiKey.token == token.value.sha()).filter(\ApiKey.type == 0).first().flatMap(to: Response.self) { uploadToken in
                guard let uploadToken = uploadToken else {
                    throw AuthError.authenticationFailed
                }
                return try req.me.verifiedTeam(id: uploadToken.teamId).flatMap(to: Response.self) { team in
                    return try AppsManager.upload(team: team, on: req)
                }
            }
        }
        
        // Upload a build from authenticated session (browser, app, etc ...)
        secure.post("teams", UUID.parameter, "builds") { (req) -> Future<Response> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: Response.self) { (team) -> Future<Response> in
                return try AppsManager.upload(team: team, on: req)
            }
        }
    }
    
}
