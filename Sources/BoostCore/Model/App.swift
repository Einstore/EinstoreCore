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


public typealias Apps = [App.Public]


final public class App: DbCoreModel {
    
    /// Platform
    public enum Platform: String, Codable, CaseIterable, ReflectionDecodable {
        case unknown
        case ios = "ios"
        case tvos = "tvos"
        case url = "url"
        case simulator = "simulator"
        case android = "android"
        case macos = "macos"
        case windows = "windows"
        
        /// All available cases
        public static var allCases: [Platform] {
            return [
                .unknown,
                .ios,
                .tvos,
                .url,
                .simulator,
                .android,
                .macos,
                .windows
            ]
        }
        
        /// File extension
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
        
        /// File MIME
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
    
    public struct Public: DbCoreModel {
        
        public var id: DbCoreIdentifier?
        public var teamId: DbCoreIdentifier?
        public var name: String
        public var identifier: String
        public var version: String
        public var build: String
        public var platform: Platform
        public var created: Date
        public var size: Int
        public var info: String?
        public var hasIcon: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamId = "team_id"
            case name
            case identifier
            case version
            case build
            case platform
            case created
            case size
            case info
            case hasIcon = "icon"
        }
        
        public init(_ app: App) {
            self.id = app.id
            self.teamId = app.teamId
            self.name = app.name
            self.identifier = app.identifier
            self.version = app.version
            self.build = app.build
            self.platform = app.platform
            self.created = app.created
            self.size = app.size
            self.info = app.info
            self.hasIcon = app.hasIcon
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
    public var size: Int
    public var sizeTotal: Int
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
        case size
        case sizeTotal = "size_total"
        case info
        case hasIcon = "icon"
    }


    public init(id: DbCoreIdentifier? = nil, teamId: DbCoreIdentifier? = nil, clusterId: DbCoreIdentifier, name: String, identifier: String, version: String, build: String, platform: Platform, size: Int, sizeTotal: Int, info: String? = nil, hasIcon: Bool = false) {
        self.id = id
        self.teamId = teamId
        self.clusterId = clusterId
        self.name = name
        self.identifier = identifier
        self.version = version
        self.build = build
        self.platform = platform
        self.created = Date()
        self.size = size
        self.sizeTotal = sizeTotal
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
            schema.field(for: \App.id, isIdentifier: true)
            schema.field(for: \App.teamId)
            schema.field(for: \App.clusterId)
            schema.field(for: \.name, type: .varchar(140))
            schema.field(for: \.identifier, type: .varchar(140))
            schema.field(for: \.version, type: .varchar(20))
            schema.field(for: \.build, type: .varchar(20))
            schema.field(for: \.platform, type: .varchar(10))
            schema.field(for: \App.created)
            schema.field(for: \App.size)
            schema.field(for: \App.sizeTotal)
            schema.field(for: \.info, type: .text)
            schema.field(for: \App.hasIcon, type: .boolean)
        }
    }
    
    public static func revert(on connection: DbCoreConnection) -> Future<Void> {
        return Database.delete(App.self, on: connection)
    }
    
}

