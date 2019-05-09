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
        public var latestBuildName: String
        public var latestBuildVersion: String
        public var latestBuildBuildNo: String
        public var latestBuildAdded: Date?
        public var latestBuildId: DbIdentifier?
        public var latestBuildHasIcon: Bool
        public var buildCount: Int
        public var platform: Build.Platform
        public var identifier: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamId = "team_id"
            case latestBuildName = "latest_build_name"
            case latestBuildVersion = "latest_build_version"
            case latestBuildBuildNo = "latest_build_buildno"
            case latestBuildAdded = "latest_build_added"
            case latestBuildId = "latest_build_id"
            case latestBuildHasIcon = "latest_build_icon"
            case buildCount = "build_count"
            case platform
            case identifier
        }
        
        public init(_ cluster: Cluster) {
            self.id = cluster.id
            self.teamId = cluster.teamId
            self.latestBuildName = cluster.latestBuildName
            self.latestBuildVersion = cluster.latestBuildVersion
            self.latestBuildBuildNo = cluster.latestBuildBuildNo
            self.latestBuildAdded = cluster.latestBuildAdded
            self.latestBuildId = cluster.latestBuildId
            self.latestBuildHasIcon = cluster.latestBuildHasIcon
            self.buildCount = cluster.buildCount
            self.platform = cluster.platform
            self.identifier = cluster.identifier
        }
        
    }
    
    public var id: DbIdentifier?
    public var teamId: DbIdentifier?
    public var latestBuildName: String
    public var latestBuildVersion: String
    public var latestBuildBuildNo: String
    public var latestBuildAdded: Date
    public var latestBuildId: DbIdentifier?
    public var latestBuildHasIcon: Bool
    public var buildCount: Int
    public var platform: Build.Platform
    public var identifier: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case latestBuildName = "latest_build_name"
        case latestBuildVersion = "latest_build_version"
        case latestBuildBuildNo = "latest_build_buildno"
        case latestBuildAdded = "latest_build_added"
        case latestBuildId = "latest_build_id"
        case latestBuildHasIcon = "latest_build_icon"
        case buildCount = "build_count"
        case platform
        case identifier
    }
    
    public init(id: DbIdentifier? = nil, latestBuild: Build, appCount: Int = 1) {
        self.id = id
        self.teamId = latestBuild.teamId
        self.latestBuildName = latestBuild.name
        self.latestBuildVersion = latestBuild.version
        self.latestBuildBuildNo = latestBuild.build
        self.latestBuildAdded = latestBuild.created
        self.latestBuildId = latestBuild.id
        self.latestBuildHasIcon = latestBuild.hasIcon
        self.buildCount = appCount
        self.platform = latestBuild.platform
        self.identifier = latestBuild.identifier
    }
    
}

// MARK: - Relationships

extension Cluster {
    
    var builds: Children<Cluster, Build> {
        return children(\Build.clusterId)
    }
    
}

// MARK: - Migrations

extension Cluster: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.teamId)
            schema.field(for: \.latestBuildName, type: .varchar(140))
            schema.field(for: \.latestBuildVersion, type: .varchar(20))
            schema.field(for: \.latestBuildBuildNo, type: .varchar(20))
            schema.field(for: \.latestBuildId)
            schema.field(for: \.latestBuildAdded)
            schema.field(for: \.latestBuildHasIcon)
            schema.field(for: \.buildCount)
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
    
    func add(build: Build, on req: Request) -> Future<Cluster> {
        latestBuildName = build.name
        latestBuildVersion = build.version
        latestBuildBuildNo = build.build
        latestBuildAdded = build.created
        latestBuildHasIcon = build.hasIcon
        return save(on: req)
    }
    
}
