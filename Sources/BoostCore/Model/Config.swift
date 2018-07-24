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
    
    public struct Theme: Content {
        
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
    
    public struct Apps: Content {
        public let ios: String?
        public let android: String?
    }
    
    public var id: DbCoreIdentifier?
    public var teamId: DbCoreIdentifier?
    public var theme: Theme
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case theme
    }
    
    public init(id: DbCoreIdentifier? = nil, teamId: DbCoreIdentifier, theme: Theme) {
        self.id = id
        self.teamId = teamId
        self.theme = theme
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
    
//    public static func prepare(on connection: DbCoreConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { (schema) in
//            schema.field(for: \Config.id)
//            schema.field(for: \Config.teamId)
//            schema.field(for: \.theme)
//        }
//    }
//    
//    public static func revert(on connection: DbCoreConnection) -> Future<Void> {
//        return Database.delete(Config.self, on: connection)
//    }
    
}
