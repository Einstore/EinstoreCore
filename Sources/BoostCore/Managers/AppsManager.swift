//
//  AppsManager.swift
//  ApiCore
//
//  Created by Ondrej Rafaj on 02/12/2018.
//

import Foundation
import Vapor
import ApiCore
import ErrorsCore
import Fluent
import FluentPostgreSQL
import SwiftShell


public class AppsManager {

    /// Overview app query
    static func overviewQuery(teams: Teams, on req: Request) throws -> QueryBuilder<ApiCoreDatabase, Cluster.Public> {
        let q = try Cluster.query(on: req).filter(\Cluster.teamId ~~ teams.ids).sort(\Cluster.latestAppAdded, .descending).decode(Cluster.Public.self).paginate(on: req)
        return q
    }
    
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
    
    static func delete(cluster: Cluster?, on req: Request) throws -> Future<Response> {
        guard let cluster = cluster, let teamId = cluster.teamId else {
            throw AppsController.Error.clusterInconsistency
        }
        return try req.me.verifiedTeam(id: teamId).flatMap(to: Response.self) { team in
            return try cluster.apps.query(on: req).all().flatMap(to: Response.self) { apps in
                var futures: [Future<Void>] = []
                try apps.forEach({
                    try futures.append(contentsOf: self.delete(app: $0, on: req))
                })
                
                return try futures.flatten(on: req).asResponse(to: req)
            }
        }
    }
    
    static func delete(app: App, countCluster cluster: Cluster? = nil, on req: Request) throws -> [Future<Void>] {
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
                        throw AppsController.Error.clusterInconsistency
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
    
}
