//
//  TeamTag.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 01/12/2018.
//

import Foundation
import Fluent
import ApiCore
import Vapor


/// Join table between Teams and Tags
public final class TeamTag: ModifiablePivot, DbCoreModel {
    
    public typealias Left = Team
    public typealias Right = Tag
    
    public static var leftIDKey: WritableKeyPath<TeamTag, DbIdentifier> {
        return \.teamId
    }
    
    public static var rightIDKey: WritableKeyPath<TeamTag, DbIdentifier> {
        return \.tagId
    }
    
    public var id: DbIdentifier?
    public var teamId: DbIdentifier
    public var tagId: DbIdentifier
    
    // MARK: Initialization
    
    public init(_ left: TeamTag.Left, _ right: TeamTag.Right) throws {
        teamId = try left.requireID()
        tagId = try right.requireID()
    }
    
    public init(teamId: DbIdentifier, tagId: DbIdentifier) throws {
        self.teamId = teamId
        self.tagId = tagId
    }
    
}

// MARK: - Migrations

extension TeamTag: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \TeamTag.id, isIdentifier: true)
            schema.field(for: \TeamTag.teamId)
            schema.field(for: \TeamTag.tagId)
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(TeamTag.self, on: connection)
    }
}
