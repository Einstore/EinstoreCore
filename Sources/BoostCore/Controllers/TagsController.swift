//
//  TagsController.swift
//  App
//
//  Created by Ondrej Rafaj on 09/12/2017.
//

import Foundation
import Vapor
import ApiCore
import Fluent
import FluentPostgreSQL
import ErrorsCore


class TagsController: Controller {
    
    static func boot(router: Router, secure: Router, debug: Router) throws {
        // Tags for an app
        secure.get("apps", DbIdentifier.parameter, "tags") { (req) -> Future<Tags> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try TagsManager.tags(appId: appId, on: req)
        }
        
        // Submit new tags
        secure.post("apps", DbIdentifier.parameter, "tags") { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try [String].fill(post: req).flatMap(to: Response.self) { tags in
                guard !tags.isEmpty else {
                    throw ErrorsCore.HTTPError.missingRequestData
                }
                return try req.me.teams().flatMap(to: Response.self) { teams in
                    return try App.query(on: req).safeApp(appId: appId, teamIds: teams.ids).first().flatMap(to: Response.self) { app in
                        guard let app = app else {
                            throw ErrorsCore.HTTPError.notFound
                        }
                        return try TagsManager.save(tags: tags, for: app, on: req).asResponse(to: req)
                    }
                }
            }
        }
        
        // Delete a tag
        secure.delete("apps", DbIdentifier.parameter, "tags", DbIdentifier.parameter) { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbIdentifier.self)
            let tagId = try req.parameters.next(DbIdentifier.self)
            return try TagsManager.delete(tagId: tagId, appId: appId, on: req).asResponse(to: req)
        }
        
        // Find apps with specific tags
        
        // Display tag stats for selected tags
    }
    
}
