//
//  Cluster.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 04/05/2018.
//

import Foundation
import ApiCore
import Vapor
import Fluent
import FluentPostgreSQL


public typealias Clusters = [Cluster]


/// Cluster is a logical entry grouping apps bundle id and platform
final public class Cluster: DbCoreModel {
    
    public struct Id: Codable {

        public var value: DbIdentifier?

        enum CodingKeys: String, CodingKey {
            case value = "id"
        }

    }

    
    public struct Public: Model, Content, Equatable {
        
        public static var idKey = \Public.id
        
        public typealias Database = ApiCoreDatabase
        
        public var id: DbIdentifier?
        public var teamId: DbIdentifier?
        public var latestAppName: String
        public var latestAppVersion: String
        public var latestAppBuild: String
        public var latestAppAdded: Date?
        public var latestAppId: DbIdentifier?
        public var latestAppHasIcon: Bool
        public var appCount: Int
        public var platform: App.Platform
        public var identifier: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamId = "team_id"
            case latestAppName = "latest_build_name"
            case latestAppVersion = "latest_build_version"
            case latestAppBuild = "latest_build_buildno"
            case latestAppAdded = "latest_build_added"
            case latestAppId = "latest_build_id"
            case latestAppHasIcon = "latest_build_icon"
            case appCount = "build_count"
            case platform
            case identifier
        }
        
        public init(_ cluster: Cluster) {
            self.id = cluster.id
            self.teamId = cluster.teamId
            self.latestAppName = cluster.latestAppName
            self.latestAppVersion = cluster.latestAppVersion
            self.latestAppBuild = cluster.latestAppBuild
            self.latestAppAdded = cluster.latestAppAdded
            self.latestAppId = cluster.latestAppId
            self.latestAppHasIcon = cluster.latestAppHasIcon
            self.appCount = cluster.appCount
            self.platform = cluster.platform
            self.identifier = cluster.identifier
        }
        
    }
    
    public var id: DbIdentifier?
    public var teamId: DbIdentifier?
    public var latestAppName: String
    public var latestAppVersion: String
    public var latestAppBuild: String
    public var latestAppAdded: Date
    public var latestAppId: DbIdentifier?
    public var latestAppHasIcon: Bool
    public var appCount: Int
    public var platform: App.Platform
    public var identifier: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case latestAppName = "latest_build_name"
        case latestAppVersion = "latest_build_version"
        case latestAppBuild = "latest_build_buildno"
        case latestAppAdded = "latest_build_added"
        case latestAppId = "latest_build_id"
        case latestAppHasIcon = "latest_build_icon"
        case appCount = "build_count"
        case platform
        case identifier
    }
    
    public init(id: DbIdentifier? = nil, latestApp: App, appCount: Int = 1) {
        self.id = id
        self.teamId = latestApp.teamId
        self.latestAppName = latestApp.name
        self.latestAppVersion = latestApp.version
        self.latestAppBuild = latestApp.build
        self.latestAppAdded = latestApp.created
        self.latestAppId = latestApp.id
        self.latestAppHasIcon = latestApp.hasIcon
        self.appCount = appCount
        self.platform = latestApp.platform
        self.identifier = latestApp.identifier
    }
    
}

// MARK: - Relationships

extension Cluster {
    
    var apps: Children<Cluster, App> {
        return children(\App.clusterId)
    }
    
}

// MARK: - Migrations

extension Cluster: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.teamId)
            schema.field(for: \.latestAppName, type: .varchar(140))
            schema.field(for: \.latestAppVersion, type: .varchar(20))
            schema.field(for: \.latestAppBuild, type: .varchar(20))
            schema.field(for: \.latestAppId)
            schema.field(for: \.latestAppAdded)
            schema.field(for: \.latestAppHasIcon)
            schema.field(for: \.appCount)
            schema.field(for: \.platform, type: .varchar(10))
            schema.field(for: \.identifier, type: .varchar(140))
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(Cluster.self, on: connection)
    }
    
}

// MARK: Tools

extension Cluster {
    
    func add(app: App, on req: Request) -> Future<Cluster> {
        latestAppName = app.name
        latestAppVersion = app.version
        latestAppBuild = app.build
        latestAppAdded = app.created
        latestAppHasIcon = app.hasIcon
        return save(on: req)
    }
    
}
