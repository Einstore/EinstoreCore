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
    
    public var id: DbIdentifier?
    public var name: String
    public var identifier: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case identifier
    }
    
    public init(id: DbIdentifier? = nil, name: String, identifier: String) {
        self.id = id
        self.name = name
        self.identifier = identifier
    }
    
}

// MARK: - Relationships

extension Tag {
    
    var apps: Siblings<Tag, App, AppTag> {
        return siblings()
    }
    
}

// MARK: - Migrations

extension Tag: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.name, type: .varchar(255))
            schema.field(for: \.identifier, type: .varchar(255))
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(Tag.self, on: connection)
    }
    
}
