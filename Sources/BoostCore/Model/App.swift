//
//  App.swift
//  App
//
//  Created by Ondrej Rafaj on 09/12/2017.
//

import Foundation
import Vapor
import Fluent
import FluentPostgreSQL
import DbCore
import ApiCore


public typealias Apps = [App]


final public class App: DbCoreModel {
    
    public enum Platform: String, Codable, CaseIterable, ReflectionDecodable {
        
        // TODO: The following needs to be refactored as it only contains "guessed" values!!!!!!!!!
        public static func keyStringIsTrue(_ item: App.Platform) -> Bool {
            return true
        }
        
        public static func reflectDecoded() throws -> (App.Platform, App.Platform) {
            return (.ios, .unknown)
        }
        
        case unknown
        case ios = "ios"
        case tvos = "tvos"
        case url = "url"
        case simulator = "simulator"
        case android = "android"
        case macos = "macos"
        case windows = "windows"
        
        public var fileExtension: String {
            switch self {
            case .ios:
                return "ipa"
            case .android:
                return "apk"
            default:
                return "app.boost"
            }
        }
        
        public var mime: String {
            switch self {
            case .ios:
                return "application/octet-stream"
            case .android:
                return "application/vnd.android.package-archive"
            default:
                return "application/unknown"
            }
        }
        
    }
    
    public struct Info: Content {
        
        public var teamId: DbCoreIdentifier
        public var apps: Int
        public var builds: Int
        
    }
    
    public static var idKey: WritableKeyPath<App, DbCoreIdentifier?> = \App.id
    
    public var id: DbCoreIdentifier?
    public var teamId: DbCoreIdentifier?
    public var clusterId: DbCoreIdentifier
    public var name: String
    public var identifier: String
    public var version: String
    public var build: String
    public var platform: Platform
    public var created: Date
    public var modified: Date
    public var info: String?
    public var hasIcon: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case clusterId = "cluster_id"
        case name
        case identifier
        case version
        case build
        case platform
        case created
        case modified
        case info
        case hasIcon = "icon"
    }


    public init(id: DbCoreIdentifier? = nil, teamId: DbCoreIdentifier? = nil, clusterId: DbCoreIdentifier, name: String, identifier: String, version: String, build: String, platform: Platform, info: String? = nil, hasIcon: Bool = false) {
        self.id = id
        self.teamId = teamId
        self.clusterId = clusterId
        self.name = name
        self.identifier = identifier
        self.version = version
        self.build = build
        self.platform = platform
        self.created = Date()
        self.modified = Date()
        self.info = info
        self.hasIcon = hasIcon
    }
    
}

// MARK: - Relationships

extension App {
    
    var tags: Siblings<App, Tag, AppTag> {
        return siblings()
    }
    
    var downloadKeys: Children<App, DownloadKey> {
        return children(\.appId)
    }
    
    var cluster: Parent<App, Cluster> {
        return parent(\App.clusterId)
    }
    
}

// MARK: - Migrations

extension App: Migration {
    
    public static func prepare(on connection: DbCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \App.id)
            schema.field(for: \App.teamId)
            schema.field(for: \App.clusterId)
            schema.field(for: \.name, type: .varchar(140))
            schema.field(for: \.identifier, type: .varchar(140))
            schema.field(for: \.version, type: .varchar(20))
            schema.field(for: \.build, type: .varchar(20))
            schema.field(for: \.platform, type: .varchar(10))
            schema.field(for: \App.created)
            schema.field(for: \App.modified)
            schema.field(for: \.info, type: .text)
            schema.field(for: \App.hasIcon, type: .boolean)
        }
    }
    
    public static func revert(on connection: DbCoreConnection) -> Future<Void> {
        return Database.delete(App.self, on: connection)
    }
    
}

