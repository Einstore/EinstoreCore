//
//  Download.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 21/11/2018.
//

import Foundation
import ApiCore
import Vapor
import Fluent
import FluentPostgreSQL


public typealias Downloads = [Download]


final public class Download: DbCoreModel {
    
    public enum Action: Int, Codable {
        case download = 0
        case opened = 1
    }
    
    public struct Public: Content {
        public var user: User
        public var created: Date
    }
    
    public var id: DbIdentifier?
    public var buildId: DbIdentifier
    public var userId: DbIdentifier
    public var teamId: DbIdentifier
    public var action: Action
    public var created: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "download_id"
        case buildId = "build_id"
        case userId = "user_id"
        case teamId = "team_id"
        case action
        case created
    }
    
    public init(id: DbIdentifier? = nil, buildId: DbIdentifier, userId: DbIdentifier, teamId: DbIdentifier, action: Action) {
        self.id = id
        self.buildId = buildId
        self.userId = userId
        self.teamId = teamId
        self.action = action
        self.created = Date()
    }
    
}

// MARK: - Relationships

extension Download {
    
    var app: Parent<Download, Build> {
        return parent(\Download.buildId)
    }
    
    var user: Parent<Download, User> {
        return parent(\Download.userId)
    }
    
}

// MARK: - Migrations

extension Download: Migration {
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(Download.self, on: connection)
    }
    
}
