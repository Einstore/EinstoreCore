//
//  UsedTagsManager.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 18/02/2019.
//

import Foundation
import Vapor
import ApiCore
import ErrorsCore
import Fluent
import FluentPostgreSQL
import DatabaseKit
import SQL


public class UsedTagsManager {
    
    /// Save used tags stats
    public static func add(statsFor tag: Tag, on req: Request) throws -> EventLoopFuture<UsedTag> {
        guard let id = tag.id else {
            throw ErrorsCore.HTTPError.notFound
        }
        return UsedTag.query(on: req).filter(\UsedTag.tagId == id).first().flatMap(to: UsedTag.self) { object in
            guard let object = object else {
                let object = UsedTag(teamId: tag.teamId, tagId: id)
                return object.save(on: req)
            }
            object.uses += 1
            return object.save(on: req)
        }
    }
    
    /// Retrieve used tag info
    public static func get(for teamId: DbIdentifier? = nil, on req: Request) throws -> EventLoopFuture<[UsedTag.Public]> {
        let q = UsedTag.query(on: req).join(\Tag.id, to: \UsedTag.tagId).sort(\UsedTag.uses, .descending).range(lower: 0, upper: 9).alsoDecode(Tag.self)
        if let teamId = teamId {
            q.filter(\UsedTag.teamId == teamId)
        } else {
            return try req.me.teams().flatMap(to: [UsedTag.Public].self) { teams in
                q.filter(\UsedTag.teamId ~~ teams.ids)
                return q.all().toPublic()
            }
        }
        return q.all().toPublic()
    }

}
