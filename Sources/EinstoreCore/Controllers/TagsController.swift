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
        secure.get("builds", DbIdentifier.parameter, "tags") { (req) -> Future<Tags> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try TagsManager.tags(appId: appId, on: req)
        }
        
        // Submit new tags
        secure.post("builds", DbIdentifier.parameter, "tags") { (req) -> Future<Response> in
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
        secure.delete("builds", DbIdentifier.parameter, "tags", DbIdentifier.parameter) { (req) -> Future<Response> in
            let appId = try req.parameters.next(DbIdentifier.self)
            let tagId = try req.parameters.next(DbIdentifier.self)
            return try TagsManager.delete(tagId: tagId, appId: appId, on: req).asResponse(to: req)
        }
        
        // Display tag stats for selected tags
        
        // Tags available for a team
        secure.get("teams", DbIdentifier.parameter, "tags") { (req) -> Future<[String]> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: [String].self) { team in
                var search: [String] = []
                if let searchTerm = req.query.search {
                    search.append(searchTerm)
                }
                return try TagsManager.tags(identifiers: search, team: team, on: req)
            }
        }
        
        // Most commonly used tags for a team
        secure.get("teams", DbIdentifier.parameter, "tags", "common") { (req) -> Future<[UsedTag.Public]> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: [UsedTag.Public].self) { team in
                return try UsedTagsManager.get(for: teamId, on: req)
            }
        }
        
        // Tags available to user
        secure.get("tags") { (req) -> Future<[String]> in
            var search: [String] = []
            if let searchTerm = req.query.search {
                search.append(searchTerm)
            }
            return try TagsManager.tags(identifiers: search, team: nil, on: req)
        }
        
        // Most commonly used tags across the teams
        secure.get("tags", "common") { (req) -> Future<[UsedTag.Public]> in
            return try UsedTagsManager.get(on: req)
        }
    }
    
}
