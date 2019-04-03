//
//  Tag.swift
//  App
//
//  Created by Ondrej Rafaj on 09/12/2017.
//

import Foundation
import ApiCore
import Vapor
import Fluent
import FluentPostgreSQL


public typealias Tags = [Tag]


final public class Tag: DbCoreModel {
    
    public struct Identifier: Content {
        
        public var identifier: String
        
        // TODO: Remove when https://github.com/vapor/fluent/pull/596 gets merged
        enum CodingKeys: String, CodingKey {
            case identifier = "fluentAggregate"
        }
        
        public init(identifier: String) {
            self.identifier = identifier
        }
        
    }
    
    public var id: DbIdentifier?
    public var teamId: DbIdentifier
    public var identifier: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case identifier
    }
    
    public init(id: DbIdentifier? = nil, teamId: DbIdentifier, identifier: String) {
        self.id = id
        self.teamId = teamId
        self.identifier = identifier
    }
    
}

// MARK: - Relationships

extension Tag {
    
    var apps: Siblings<Tag, App, AppTag> {
        return siblings()
    }
    
    var team: Parent<Tag, Team> {
        return parent(\Tag.teamId)
    }
    
    var usedTagInfo: Children<Tag, UsedTag> {
        return children(\UsedTag.tagId)
    }
    
}

// MARK: - Migrations

extension Tag: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.teamId)
            schema.field(for: \.identifier, type: .varchar(80))
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(Tag.self, on: connection)
    }
    
}
