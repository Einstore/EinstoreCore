//
//  Build.swift
//  App
//
//  Created by Ondrej Rafaj on 09/12/2017.
//

import Foundation
import Vapor
import Fluent
import FluentPostgreSQL
import ApiCore


public typealias Builds = [Build.Public]


final public class Build: DbCoreModel {
    
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
        
        /// Build detail link
        public var link: String
        
        /// System wide template data
        public var system: FrontendSystemData
        
        /// Build info
        public var build: Build
        
        /// Initializer
        ///
        /// - Parameters:
        ///   - verification: Verification token
        ///   - link: Build detail link value (optional)
        ///   - build: Build model
        ///   - user: User model
        ///   - req: Request
        /// - Throws: whatever comes it's way
        public init(link: String? = nil, build: Build, user: User, on req: Request) throws {
            self.user = user
            let serverUrl = ApiCoreBase.configuration.server.interface ?? req.serverURL().absoluteString
            self.link = link ?? serverUrl.finished(with: "/") + "build/\(build.id?.uuidString ?? "error")"
            system = try FrontendSystemData(req)
            self.build = build
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
        public var clusterId: DbIdentifier
        public var name: String
        public var identifier: String
        public var version: String
        public var build: String
        public var platform: Platform
        public var created: Date
        public var built: Date?
        public var size: Int
        public var info: Info?
        public var minSdk: String?
        public var iconHash: String?
        
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
            case built
            case size
            case info
            case minSdk
            case iconHash = "icon"
        }
        
        public init(_ build: Build) {
            id = build.id
            teamId = build.teamId
            clusterId = build.clusterId
            name = build.name
            identifier = build.identifier
            version = build.version
            self.build = build.build
            platform = build.platform
            created = build.created
            built = build.built
            size = build.size
            info = build.info
            minSdk = build.minSdk
            iconHash = build.iconHash
        }
        
        public var hasIcon: Bool {
            return iconHash != nil
        }
        
    }
    
    public struct Overview: Content {
        
        public var teamId: DbIdentifier
        public var apps: Int
        public var builds: Int
        
    }
    
    public static var idKey: WritableKeyPath<Build, DbIdentifier?> = \Build.id
    
    public var id: DbIdentifier?
    public var teamId: DbIdentifier
    public var clusterId: DbIdentifier
    public var name: String
    public var identifier: String
    public var version: String
    public var build: String
    public var platform: Platform
    public var created: Date
    public var built: Date?
    public var size: Int
    public var sizeTotal: Int
    public var info: Info?
    public var minSdk: String?
    public var iconHash: String?
    
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
        case built
        case size
        case sizeTotal = "size_total"
        case info
        case minSdk = "min_sdk"
        case iconHash = "icon"
    }

    public init(id: DbIdentifier? = nil, teamId: DbIdentifier, clusterId: DbIdentifier, name: String, identifier: String, version: String, build: String, platform: Platform, built: Date?, size: Int, sizeTotal: Int, info: Info? = nil, minSdk: String? = nil, iconHash: String? = nil) {
        self.id = id
        self.teamId = teamId
        self.clusterId = clusterId
        self.name = name
        self.identifier = identifier
        self.version = version
        self.build = build
        self.platform = platform
        self.created = Date()
        self.built = built
        self.size = size
        self.sizeTotal = sizeTotal
        self.info = info
        self.minSdk = minSdk
        self.iconHash = iconHash
    }
    
    public var hasIcon: Bool {
        return iconHash != nil
    }
    
}

// MARK: - Relationships

extension Build {
    
    var team: Parent<Build, Team> {
        return parent(\Build.teamId)
    }
    
    var tags: Siblings<Build, Tag, BuildTag> {
        return siblings()
    }
    
    var downloadKeys: Children<Build, DownloadKey> {
        return children(\.buildId)
    }
    
    var app: Parent<Build, Cluster> {
        return parent(\Build.clusterId)
    }
    
}

// MARK: - Migrations

extension Build: Migration {
    
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
            schema.field(for: \.built)
            schema.field(for: \.size)
            schema.field(for: \.sizeTotal)
            
            // TODO: change to `schema.field(for: \.info, type: .jsonb)` when this gets fixed: https://github.com/vapor/fluent/issues/594
            let col = PostgreSQLColumnDefinition.columnDefinition(.column(nil, "info"), .jsonb, [])
            schema.field(col)
            
            schema.field(for: \.iconHash, type: .varchar(32))
            schema.field(for: \.minSdk, type: .varchar(20))
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(Build.self, on: connection)
    }
    
}

