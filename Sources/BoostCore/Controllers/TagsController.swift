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
                        return Team.query(on: req).filter(\Team.id == app.teamId).first().flatMap(to: Response.self) { team in
                            guard let team = team else {
                                throw ErrorsCore.HTTPError.notFound
                            }
                            return try TagsManager.save(tags: tags, for: app, team: team, on: req).asResponse(to: req)
                        }
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
        secure.get("apps") { (req) -> Future<Response> in
            guard let search = req.query.search else {
                throw ErrorsCore.HTTPError.missingSearchParams
            }
            fatalError()
        }
        
        // Find builds with specific tags
        secure.get("apps", DbIdentifier.parameter) { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbIdentifier.self)
            fatalError()
        }
        
        // Display tag stats for selected tags
        
        // Tags available for a team
        secure.get("teams", DbIdentifier.parameter, "tags") { (req) -> Future<Tags> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: Tags.self) { team in
                // TODO: Pass searched identifiers
                return try TagsManager.tags(identifiers: [], team: team, on: req)
            }
        }
        
        // Tags available to user
        secure.get("tags") { (req) -> Future<Tags> in
            return try TagsManager.tags(identifiers: [], team: nil, on: req)
        }
    }
    
}
