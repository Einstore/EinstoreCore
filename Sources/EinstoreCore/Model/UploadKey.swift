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
import ApiCore


public typealias UploadKeys = [UploadKey]


final public class UploadKey: DbCoreModel {
    
    public struct Token: Codable {
        
        public var value: String
        
        enum CodingKeys: String, CodingKey {
            case value = "token"
        }
        
    }
    
    public typealias TokenType = Int
    
    public struct New: Codable {
        public var name: String
        public var type: TokenType
        public var expires: Date?
    }
    
    public struct Display: DbCoreModel {
        
        public var id: DbIdentifier?
        public var teamId: DbIdentifier
        public var name: String
        public var type: TokenType
        public var expires: Date?
        public var created: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamId = "team_id"
            case name
            case type
            case expires
            case created
        }
        
        public init(id: DbIdentifier? = nil, teamId: DbIdentifier, name: String, type: TokenType, created: Date, expires: Date? = Date()) {
            self.id = id
            self.teamId = teamId
            self.name = name
            self.type = type
            self.expires = expires
            self.created = created
        }
        
        init(key: UploadKey) {
            id = key.id
            teamId = key.teamId
            name = key.name
            type = key.type
            expires = key.expires
            created = key.created
        }
        
    }
    
    public var id: DbIdentifier?
    public var teamId: DbIdentifier
    public var name: String
    public var expires: Date?
    public var token: String
    public var type: TokenType
    public var created: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case name
        case expires
        case token
        case type
        case created
    }
    
    public init(id: DbIdentifier? = nil, teamId: DbIdentifier, name: String, expires: Date? = nil, token: String = UUID().uuidString, type: TokenType) {
        self.id = id
        self.teamId = teamId
        self.name = name
        self.expires = expires
        self.token = token
        self.type = type
        self.created = Date()
    }
    
    public init(new: New, teamId: DbIdentifier) {
        self.teamId = teamId
        self.name = new.name
        self.expires = new.expires
        self.token = UUID().uuidString
        self.type = new.type
        self.created = Date()
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
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.teamId, type: .uuid)
            schema.field(for: \.name, type: .varchar(60))
            schema.field(for: \.expires)
            schema.field(for: \.created)
            schema.field(for: \.token, type: .varchar(64))
            schema.field(for: \.type, type: .int)
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(UploadKey.self, on: connection)
    }
    
}

// MARK: - Helpers

extension UploadKey {
    
    public func asDisplay() -> UploadKey.Display {
        return UploadKey.Display(key: self)
    }
    
}
