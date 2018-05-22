//
//  Cluster.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 04/05/2018.
//

import Foundation
import DbCore
import Vapor
import Fluent
import FluentPostgreSQL


public typealias Clusters = [Cluster]


final public class Cluster: DbCoreModel {
    
    public struct Public: Content {
        
        public var latestAppName: String
        public var latestAppVersion: String
        public var latestAppBuild: String
        public var latestAppAdded: Date?
        public var appCount: Int
        public var platform: App.Platform
        public var identifier: String
        
        enum CodingKeys: String, CodingKey {
            case latestAppName = "latest_app_name"
            case latestAppVersion = "latest_app_version"
            case latestAppBuild = "latest_app_build"
            case latestAppAdded = "latest_app_added"
            case appCount = "app_count"
            case platform
            case identifier
        }
        
        public init(_ cluster: Cluster) {
            self.latestAppName = cluster.latestAppName
            self.latestAppVersion = cluster.latestAppVersion
            self.latestAppBuild = cluster.latestAppBuild
            self.latestAppAdded = cluster.latestAppAdded
            self.appCount = cluster.appCount
            self.platform = cluster.platform
            self.identifier = cluster.identifier
        }
        
    }
    
    public var id: DbCoreIdentifier?
    public var teamId: DbCoreIdentifier?
    public var latestAppName: String
    public var latestAppVersion: String
    public var latestAppBuild: String
    public var latestAppAdded: Date
    public var appCount: Int
    public var platform: App.Platform
    public var identifier: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case latestAppName = "latest_app_name"
        case latestAppVersion = "latest_app_version"
        case latestAppBuild = "latest_app_build"
        case latestAppAdded = "latest_app_added"
        case appCount = "app_count"
        case platform
        case identifier
    }
    
    public init(id: DbCoreIdentifier? = nil, latestApp: App, appCount: Int = 1) {
        self.id = id
        self.teamId = latestApp.teamId
        self.latestAppName = latestApp.name
        self.latestAppVersion = latestApp.version
        self.latestAppBuild = latestApp.build
        self.latestAppAdded = latestApp.created
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
    
    public static func prepare(on connection: DbCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            try schema.field(for: \Cluster.id)
            try schema.field(for: \Cluster.teamId)
            schema.addField(type: DbCoreColumnType.varChar(140), name: CodingKeys.latestAppName.stringValue)
            schema.addField(type: DbCoreColumnType.varChar(20), name: CodingKeys.latestAppVersion.stringValue)
            schema.addField(type: DbCoreColumnType.varChar(20), name: CodingKeys.latestAppBuild.stringValue)
            try schema.field(for: \Cluster.latestAppAdded)
            schema.addField(type: DbCoreColumnType.bigInt(), name: CodingKeys.appCount.stringValue)
            schema.addField(type: DbCoreColumnType.varChar(10), name: CodingKeys.platform.stringValue)
            schema.addField(type: DbCoreColumnType.varChar(140), name: CodingKeys.identifier.stringValue)
        }
    }
    
    public static func revert(on connection: DbCoreConnection) -> Future<Void> {
        return Database.delete(Cluster.self, on: connection)
    }
    
}
