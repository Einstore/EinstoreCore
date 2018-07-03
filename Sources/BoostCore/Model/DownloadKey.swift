//
//  DownloadKey.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 22/02/2018.
//

import Foundation
import Vapor
import Fluent
import FluentPostgreSQL
import DbCore
import ApiCore


public typealias DownloadKeys = [DownloadKey]


final public class DownloadKey: DbCoreModel {
    
    public struct Token: Codable {
        public var token: String
    }
    
    public struct Public: Content {
        let appId: DbCoreIdentifier
        var token: String
        let plist: String
        let file: String
        let ios: String
        
        init(downloadKey: DownloadKey, request req: Request) {
            self.token = downloadKey.token
            
            guard let serverUrlString = ApiCoreBase.configuration.server.url, let url = URL(string: serverUrlString)?.appendingPathComponent("apps") else {
                fatalError("Server URL is not properly configured")
            }
            self.plist = url.appendingPathComponent("plist").absoluteString + "?token=\(downloadKey.token)"
            self.file = url.appendingPathComponent("file").absoluteString + "?token=\(downloadKey.token)"
            self.ios = "itms-services://?action=download-manifest&url=\(self.plist)"
            self.appId = downloadKey.appId
        }
        
        enum CodingKeys: String, CodingKey {
            case appId = "app_id"
            case token
            case plist
            case file
            case ios
        }
    }
    
    public var id: DbCoreIdentifier?
    public var appId: DbCoreIdentifier
    public var token: String
    public var added: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case appId = "app_id"
        case token
        case added
    }
    
    public init(id: DbCoreIdentifier? = nil, appId: DbCoreIdentifier) {
        self.id = id
        self.appId = appId
        self.token = UUID().uuidString
        self.added = Date()
    }
    
}

// MARK: - Relationships

extension DownloadKey {
    
    var app: Parent<DownloadKey, App> {
        return parent(\.appId)
    }
    
}

// MARK: - Migrations

extension DownloadKey: Migration {
    
    public static func prepare(on connection: DbCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.appId)
            schema.field(for: \.token, type: .varchar(64))
            schema.field(for: \.added)
        }
    }
    
    public static func revert(on connection: DbCoreConnection) -> Future<Void> {
        return Database.delete(DownloadKey.self, on: connection)
    }
    
}
