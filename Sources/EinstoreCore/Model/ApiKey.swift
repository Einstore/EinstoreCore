//
//  ApiKey.swift
//  App
//
//  Created by Ondrej Rafaj on 11/12/2017.
//

import Foundation
import Vapor
import Fluent
import FluentPostgreSQL
import ApiCore


public typealias ApiKeys = [ApiKey]


final public class ApiKey: DbCoreModel {
    
    public struct Token: Codable {
        
        public var value: String
        
        enum CodingKeys: String, CodingKey {
            case value = "token"
        }
        
    }
    
    public typealias TokenType = Int
    
    public struct New: Codable {
        
        public var name: String
        public var tags: String?
        public var type: TokenType
        public var expires: Date?
        public var clusterId: DbIdentifier?
        
        enum CodingKeys: String, CodingKey {
            case name
            case tags
            case type
            case expires
            case clusterId = "cluster_id"
        }
        
        public init(name: String, tags: String? = nil, type: TokenType, expires: Date? = nil, clusterId: DbIdentifier? = nil) {
            self.name = name
            self.tags = tags
            self.type = type
            self.expires = expires
            self.clusterId = clusterId
        }
        
    }
    
    public struct Update: Codable {
        
        public var name: String
        public var tags: String?
        public var expires: Date?
        
        enum CodingKeys: String, CodingKey {
            case name
            case tags
            case expires
        }
        
        public init(name: String, tags: String?, expires: Date? = nil) {
            self.name = name
            self.tags = tags
            self.expires = expires
        }
        
    }
    
    public struct Display: DbCoreModel {
        
        public var id: DbIdentifier?
        public var teamId: DbIdentifier
        public var name: String
        public var tags: String?
        public var type: TokenType
        public var clusterId: DbIdentifier?
        public var expires: Date?
        public var created: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamId = "team_id"
            case name
            case tags
            case type
            case clusterId = "cluster_id"
            case expires
            case created
        }
        
        public init(id: DbIdentifier? = nil, teamId: DbIdentifier, name: String, tags: String, type: TokenType, created: Date, expires: Date? = Date()) {
            self.id = id
            self.teamId = teamId
            self.name = name
            self.tags = tags
            self.type = type
            self.expires = expires
            self.created = created
        }
        
        init(key: ApiKey) {
            id = key.id
            teamId = key.teamId
            name = key.name
            tags = key.tags
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
    public var tags: String?
    public var type: TokenType
    public var clusterId: DbIdentifier?
    public var created: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case name
        case expires
        case token
        case tags
        case type
        case clusterId
        case created
    }
    
    public init(id: DbIdentifier? = nil, teamId: DbIdentifier, name: String, expires: Date? = nil, token: String = UUID().uuidString, tags: String? = nil, type: TokenType, clusterId: DbIdentifier? = nil) {
        self.id = id
        self.teamId = teamId
        self.name = name
        self.expires = expires
        self.token = token
        self.tags = tags
        self.type = type
        self.clusterId = clusterId
        self.created = Date()
        
        checkTags()
    }
    
    public init(new: New, teamId: DbIdentifier) {
        self.teamId = teamId
        self.name = new.name
        self.expires = new.expires
        self.token = UUID().uuidString
        self.tags = new.tags
        self.type = new.type
        self.created = Date()
        
        checkTags()
    }
    
}

// MARK: - Relations

extension ApiKey {
    
    public var team: Parent<ApiKey, Team> {
        return parent(\.teamId)
    }
    
}

// MARK: - Migrations

extension ApiKey: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.teamId, type: .uuid)
            schema.field(for: \.name, type: .varchar(60))
            schema.field(for: \.expires)
            schema.field(for: \.created)
            schema.field(for: \.token, type: .varchar(64))
            schema.field(for: \.tags)
            schema.field(for: \.type, type: .int)
            schema.field(for: \.clusterId, type: .uuid)
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(ApiKey.self, on: connection)
    }
    
}

// MARK: - Helpers

extension ApiKey {
    
    public func asDisplay() -> ApiKey.Display {
        return ApiKey.Display(key: self)
    }
    
    public func checkTags() {
        tags = tags?.replacingOccurrences(of: " ", with: ",").split(separator: ",").map({ String($0).safeTagText }).joined(separator: ",")
    }
    
}
