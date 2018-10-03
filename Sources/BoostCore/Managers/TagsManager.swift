//
//  TagsManager.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 3/10/2018.
//

import Foundation
import Vapor
import ApiCore
import ErrorsCore
import Fluent
import FluentPostgreSQL


public class TagsManager {
    
    /// Save an array of tags on an app
    public static func save(tags: [String], for app: App, on req: Request) throws -> Future<Void> {
        var futures: [Future<Void>] = []
        tags.forEach { (tagSubstring) in
            let tag = String(tagSubstring)
            let future = Tag.query(on: req).filter(\Tag.identifier == tag).first().flatMap(to: Void.self) { (tagObject) -> Future<Void> in
                guard let tagObject = tagObject else {
                    let t = Tag(id: nil, identifier: tag.safeText)
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
    
    /// Unsecured tags for an app
    public static func tags(app: App, on req: Request) throws -> Future<Tags> {
        return try app.tags.query(on: req).all()
    }
    
    /// Secured apps for a tag
    public static func tags(appId: DbIdentifier, on req: Request) throws -> Future<Tags> {
        return try req.me.teams().flatMap(to: Tags.self) { teams in
            return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().flatMap(to: Tags.self) { app in
                guard let app = app else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try tags(app: app, on: req)
            }
        }
    }
    
    public static func tags(identifier: String? = nil, bundleIdentifier: String, platform: App.Platform, on req: Request) throws -> Future<Tags> {
        fatalError()
        
    }
    
    public static func tags(identifier: String? = nil, cluster: Cluster, on req: Request) throws -> Future<Tags> {
        return try tags(identifier: identifier, bundleIdentifier: cluster.identifier, platform: cluster.platform, on: req)
    }
    
    public static func tags(identifier: String, team: Team? = nil, on req: Request) throws -> Future<Tags> {
        fatalError()
    }
    
}
