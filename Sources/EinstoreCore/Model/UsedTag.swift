//
//  UsedTag.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 18/02/2019.
//

import Foundation
import ApiCore
import Vapor
import Fluent
import FluentPostgreSQL


public typealias UsedTags = [UsedTag]


final public class UsedTag: DbCoreModel {
    
    public struct Public: DbCoreModel {
        
        public var id: DbIdentifier?
        public let identifier: String
        public let uses: Int
        
        init(tag: Tag, usedTag: UsedTag) {
            self.id = tag.id
            self.identifier = tag.identifier
            self.uses = usedTag.uses
        }
        
        enum CodingKeys: String, CodingKey {
            case identifier
            case uses
        }
    }
    
    public var id: DbIdentifier?
    public let teamId: DbIdentifier
    public let tagId: DbIdentifier
    public var uses: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case tagId = "tag_id"
        case uses
    }
    
    public init(id: DbIdentifier? = nil, teamId: DbIdentifier, tagId: DbIdentifier) {
        self.id = id
        self.teamId = teamId
        self.tagId = tagId
        uses = 1
    }
    
}

// MARK: - Relationships

extension UsedTag {
    
    var tag: Parent<UsedTag, Tag> {
        return parent(\UsedTag.tagId)
    }
    
    var team: Parent<UsedTag, Team> {
        return parent(\UsedTag.teamId)
    }
    
}

// MARK: - Migrations

extension UsedTag: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.tagId)
            schema.field(for: \.teamId)
            schema.field(for: \.uses)
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(UsedTag.self, on: connection)
    }
    
}

// MARK: Helpers

extension EventLoopFuture where T == [(UsedTag, Tag)] {
    
    public func toPublic() -> EventLoopFuture<[UsedTag.Public]> {
        return self.map(to: [UsedTag.Public].self) { arr in
            return arr.map({ UsedTag.Public(tag: $0.1, usedTag: $0.0) })
        }
    }
    
}
