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
import ApiCore


public typealias Apps = [App.Public]


final public class App: DbCoreModel {
    
    /// Detail link template
    public struct DetailTemplate: Content {
        
        /// Link
        public struct Link: Codable {
            
            /// Value of the link (URL)
            public var value: String?
            
            enum CodingKeys: String, CodingKey {
                case value = "link"
            }
            
        }
        
        /// User
        public var user: User
        
        /// App detail link
        public var link: String
        
        /// System wide template data
        public var system: FrontendSystemData
        
        /// App info
        public var app: App
        
        /// Initializer
        ///
        /// - Parameters:
        ///   - verification: Verification token
        ///   - link: App detail link value (optional)
        ///   - app: App model
        ///   - user: User model
        ///   - req: Request
        /// - Throws: whatever comes it's way
        public init(link: String? = nil, app: App, user: User, on req: Request) throws {
            self.user = user
            let serverUrl = ApiCoreBase.configuration.server.interface ?? req.serverURL().absoluteString
            self.link = link ?? serverUrl.finished(with: "/") + "build/\(app.id?.uuidString ?? "error")"
            system = try FrontendSystemData(req)
            self.app = app
        }
        
    }
    
    /// Info
    public struct Info: Codable {
        
        /// URL:Message object
        public struct URLMessagePair: Codable {
            
            /// Id
            public let id: String?
            
            /// Full URL (including protocol)
            public let url: String?
            
            /// Message
            public let message: String?
            
            /// Initializer
            public init(id: String? = nil, url: String? = nil, message: String? = nil) {
                self.id = id
                self.url = url
                self.message = message
            }
            
        }
        
        /// Source control
        public struct SourceControl: Codable {
            
            /// Full commit link
            public let commit: URLMessagePair?
            
            /// Full pull request / merge request (PR/MR) link
            public let pr: URLMessagePair?
            
            /// Initializer
            public init(commit: URLMessagePair? = nil, pr: URLMessagePair? = nil) {
                self.commit = commit
                self.pr = pr
            }
            
            enum CodingKeys: String, CodingKey {
                case commit
                case pr
            }
            
        }
        
        /// Project management
        public struct ProjectManagement: Codable {
            
            /// Ticket
            public let ticket: URLMessagePair?
            
            /// Initializer
            public init(ticket: URLMessagePair? = nil) {
                self.ticket = ticket
            }
            
            enum CodingKeys: String, CodingKey {
                case ticket
            }
            
        }
        
        /// Source control info
        public let sourceControl: SourceControl?
        
        /// Project management reference
        public let projectManagement: ProjectManagement?
        
        /// Initializer
        public init(sourceControl: SourceControl? = nil, projectManagement: ProjectManagement? = nil) {
            self.sourceControl = sourceControl
            self.projectManagement = projectManagement
        }
        
        enum CodingKeys: String, CodingKey {
            case sourceControl = "sc"
            case projectManagement = "pm"
        }
        
        /// Check if info is empty
        public var isEmpty: Bool {
            return sourceControl == nil && projectManagement == nil
        }

    }
    
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
        
        /// Returns currently supported platforms
        public static var supportedPlatforms: [Platform] {
            return [
                .ios,
                .android
            ]
        }
        
        /// Check if platform is supported
        public static func `is`(supported platform: Platform) -> Bool {
            return supportedPlatforms.contains(platform)
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
        
        public var id: DbIdentifier?
        public var teamId: DbIdentifier?
        public var name: String
        public var identifier: String
        public var version: String
        public var build: String
        public var platform: Platform
        public var created: Date
        public var size: Int
        public var info: Info?
        public var minSdk: String?
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
            case minSdk
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
            self.minSdk = app.minSdk
            self.hasIcon = app.hasIcon
        }
        
    }
    
    public struct Overview: Content {
        
        public var teamId: DbIdentifier
        public var apps: Int
        public var builds: Int
        
    }
    
    public static var idKey: WritableKeyPath<App, DbIdentifier?> = \App.id
    
    public var id: DbIdentifier?
    public var teamId: DbIdentifier
    public var clusterId: DbIdentifier
    public var name: String
    public var identifier: String
    public var version: String
    public var build: String
    public var platform: Platform
    public var created: Date
    public var size: Int
    public var sizeTotal: Int
    public var info: Info?
    public var minSdk: String?
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
        case minSdk = "min_sdk"
        case hasIcon = "icon"
    }

    public init(id: DbIdentifier? = nil, teamId: DbIdentifier, clusterId: DbIdentifier, name: String, identifier: String, version: String, build: String, platform: Platform, size: Int, sizeTotal: Int, info: Info? = nil, minSdk: String? = nil, hasIcon: Bool = false) {
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
        self.minSdk = minSdk
        self.hasIcon = hasIcon
    }
    
}

// MARK: - Relationships

extension App {
    
    var team: Parent<App, Team> {
        return parent(\App.teamId)
    }
    
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
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.teamId)
            schema.field(for: \.clusterId)
            schema.field(for: \.name, type: .varchar(140))
            schema.field(for: \.identifier, type: .varchar(140))
            schema.field(for: \.version, type: .varchar(20))
            schema.field(for: \.build, type: .varchar(20))
            schema.field(for: \.platform, type: .varchar(10))
            schema.field(for: \.created)
            schema.field(for: \.size)
            schema.field(for: \.sizeTotal)
            
            // TODO: change to `schema.field(for: \.info, type: .jsonb)` when this gets fixed: https://github.com/vapor/fluent/issues/594
            let col = PostgreSQLColumnDefinition.columnDefinition(.column(nil, "info"), .jsonb, [])
            schema.field(col)
            
            schema.field(for: \.hasIcon, type: .boolean)
            schema.field(for: \.minSdk, type: .varchar(20))
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(App.self, on: connection)
    }
    
}

