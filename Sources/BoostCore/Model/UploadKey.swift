//
//  UploadKey.swift
//  App
//
//  Created by Ondrej Rafaj on 11/12/2017.
//

import Foundation
import Vapor
import Fluent
import FluentPostgreSQL
import DbCore
import ApiCore


public typealias UploadKeys = [UploadKey]


final public class UploadKey: DbCoreModel {
    
    public struct Token: Codable {
        public var token: String
    }
    
    public struct New: Codable {
        public var name: String
        public var expires: Date?
    }
    
    public struct Display: DbCoreModel {
        
        public var id: DbCoreIdentifier?
        public var teamId: DbCoreIdentifier
        public var name: String
        public var expires: Date?
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamId = "team_id"
            case name
            case expires
        }
        
        public init(id: DbCoreIdentifier? = nil, teamId: DbCoreIdentifier, name: String, expires: Date? = Date()) {
            self.id = id
            self.teamId = teamId
            self.name = name
            self.expires = expires
        }
        
        init(key: UploadKey) {
            self.id = key.id
            self.teamId = key.teamId
            self.name = key.name
            self.expires = key.expires
        }
        
    }
    
    public var id: DbCoreIdentifier?
    public var teamId: DbCoreIdentifier
    public var name: String
    public var expires: Date?
    public var token: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case name
        case expires
        case token
    }
    
    public init(id: DbCoreIdentifier? = nil, teamId: DbCoreIdentifier, name: String, expires: Date? = nil, token: String = UUID().uuidString) {
        self.id = id
        self.teamId = teamId
        self.name = name
        self.expires = expires
        self.token = token
    }
    
    public init(new: New, teamId: DbCoreIdentifier) {
        self.teamId = teamId
        self.name = new.name
        self.expires = new.expires
        self.token = UUID().uuidString
    }
    
}

// MARK: - Relations

extension UploadKey {
    
    public var team: Parent<UploadKey, Team> {
        return parent(\.teamId)
    }
    
}

// MARK: - Migrations

extension UploadKey: Migration {
    
    public static func prepare(on connection: DbCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.teamId, type: .uuid)
            schema.field(for: \.name, type: .varchar(60))
            schema.field(for: \.expires)
            schema.field(for: \.token, type: .varchar(64))
        }
    }
    
    public static func revert(on connection: DbCoreConnection) -> Future<Void> {
        return Database.delete(UploadKey.self, on: connection)
    }
    
}

// MARK: - Helpers

extension UploadKey {
    
    public func asDisplay() -> UploadKey.Display {
        return UploadKey.Display(key: self)
    }
    
}
