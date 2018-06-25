//
//  Configuration.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 11/04/2018.
//

import Foundation
import DbCore
import Vapor
import Fluent
import FluentPostgreSQL
import ApiCore


public typealias Configs = [Config]


final public class Config: DbCoreModel {
    
    public struct Theme: PostgreSQLJSONType, Content {
        public let primaryColor: String
        public let primaryBackgroundColor: String
        public let primaryButtonColor: String
        public let primaryButtonBackgroundColor: String
        
        enum CodingKeys: String, CodingKey {
            case primaryColor = "primary_color"
            case primaryBackgroundColor = "primary_background_color"
            case primaryButtonColor = "primary_button_color"
            case primaryButtonBackgroundColor = "primary_button_background_color"
        }
    }
    
    public struct Apps: PostgreSQLJSONType, Content {
        public let ios: String?
        public let android: String?
    }
    
    public var id: DbCoreIdentifier?
    public var teamId: DbCoreIdentifier?
    public var theme: Theme
    public var apps: Apps?
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case theme
        case apps
    }
    
    public init(id: DbCoreIdentifier? = nil, teamId: DbCoreIdentifier, theme: Theme, apps: Apps? = nil) {
        self.id = id
        self.teamId = teamId
        self.theme = theme
        self.apps = apps
    }
    
}

// MARK: - Relationships

extension Config {
    
    var team: Parent<Config, Team>? {
        return parent(\Config.teamId)
    }
    
}

// MARK: - Migrations

extension Config: Migration {
    
    public static func prepare(on connection: DbCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \Config.id)
            schema.field(for: \Config.teamId)
            schema.field(for: \.theme, type: .jsonb)
            schema.field(for: \.theme, type: .jsonb)
        }
    }
    
    public static func revert(on connection: DbCoreConnection) -> Future<Void> {
        return Database.delete(Config.self, on: connection)
    }
    
}
