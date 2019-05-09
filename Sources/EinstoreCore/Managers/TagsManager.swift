//
//  TagsManager.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 3/10/2018.
//

import Foundation
import Vapor
import ApiCore
import ErrorsCore
import Fluent
import FluentPostgreSQL
import DatabaseKit
import SQL


public class TagsManager {
    
    /// Save an array of tags on an app
    public static func save(tags: [String], for build: Build, team: Team, on req: Request) throws -> Future<Tags> {
        guard let teamId = team.id else {
            throw ErrorsCore.HTTPError.missingId
        }
        return try build.tags.query(on: req).all().flatMap(to: Tags.self) { appTags in
            var futures: [Future<Tag>] = []
            tags.forEach { tagSubstring in
                let tag = String(tagSubstring).safeTagText
                guard !appTags.contains(identifier: tag) else {
                    return
                }   
                let future = Tag.query(on: req).filter(\Tag.identifier == tag).filter(\Tag.teamId == teamId).first().flatMap(to: Tag.self) {  tagObject in
                    guard let tagObject = tagObject else {
                        let t = Tag(id: nil, teamId: teamId, identifier: tag)
                        return t.save(on: req).flatMap(to: Tag.self) { tag in
                            return build.tags.attach(tag, on: req).map(to: Tag.self) { _ in
                                return tag
                            }
                        }
                    }
                    return build.tags.attach(tagObject, on: req).map(to: Tag.self) { _ in
                        return tagObject
                    }
                }
                futures.append(future)
            }
            return futures.flatten(on: req)
        }
    }
    
    /// Unsecured tags for an app
    public static func tags(build: Build, on req: Request) throws -> Future<Tags> {
        return try build.tags.query(on: req).all()
    }
    
    /// Secured apps for a tag
    public static func tags(buildId: DbIdentifier, on req: Request) throws -> Future<Tags> {
        return try req.me.teams().flatMap(to: Tags.self) { teams in
            return try Build.query(on: req).safeBuild(id: buildId, teamIds: teams.ids).first().flatMap(to: Tags.self) { build in
                guard let build = build else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try tags(build: build, on: req)
            }
        }
    }
    
    public static func delete(tag: Tag, on req: Request) throws -> Future<Void> {
        return try tag.builds.query(on: req).count().flatMap(to: Void.self) { count in
            let delete = BuildTag.query(on: req).filter(\BuildTag.tagId == tag.id!).delete()
            guard count == 1 else {
                return delete
            }
            return delete.flatMap(to: Void.self) { _ in
                return try tag.usedTagInfo.query(on: req).delete().flatMap(to: Void.self) { _ in
                    return tag.delete(on: req)
                }
            }
        }
    }
    
    public static func delete(tagId: DbIdentifier, appId: DbIdentifier, on req: Request) throws -> Future<Void> {
        return Tag.query(on: req).filter(\Tag.id == tagId).first().flatMap(to: Void.self) { tag in
            guard let tag = tag else {
                throw ErrorsCore.HTTPError.notFound
            }
            return try req.me.teams().flatMap(to: Void.self) { teams in
                return try Build.query(on: req).safeBuild(id: appId, teamIds: teams.ids).first().flatMap(to: Void.self) { build in
                    guard let _ = build else {
                        throw ErrorsCore.HTTPError.notFound
                    }
                    return try delete(tag: tag, on: req)
                }
            }
        }
    }
    
    public static func tags(identifiers: [String] = [], team: Team? = nil, on req: Request) throws -> Future<[String]> {
        func search(q: inout Fluent.QueryBuilder<PostgreSQLDatabase, Tag>, identifiers: [String]) {
            if !identifiers.isEmpty {
                q.group(.or) { q in
                    identifiers.forEach({ i in
                        q.filter(\Tag.identifier, "ILIKE", "%\(i)%")
                    })
                }
            }
            _ = q.sort(\Tag.identifier, .ascending)
            // TODO: Fix!!!!!!!!!
//            _ = q.groupBy(\Tag.identifier)
        }
        
        if let team = team, let teamId = team.id { // Search only tags attached to a specific team
            var q = Tag.query(on: req).filter(\Tag.teamId == teamId)
            search(q: &q, identifiers: identifiers)
            let tags: Future<Tags> = q.all()
            return tags.map(to: [String].self) { tags in
                let t: [String] = tags.map({ $0.identifier })
                // TODO: Fix using SQL!!!!!!!!!
                return Array(Set<String>(t)).sorted()
            }
        } else { // Search for all tags for user
            return try req.me.teams().flatMap(to: [String].self) { teams in
                var q = Tag.query(on: req).filter(\Tag.teamId ~~ teams.ids)
                // TODO: Refactor following duplicate code
                search(q: &q, identifiers: identifiers)
                let tags: Future<Tags> = q.all()
                return tags.map(to: [String].self) { tags in
                    let t: [String] = tags.map({ $0.identifier })
                    // TODO: Fix using SQL!!!!!!!!!
                    return Array(Set<String>(t)).sorted()
                }
            }
        }
    }
    
}
