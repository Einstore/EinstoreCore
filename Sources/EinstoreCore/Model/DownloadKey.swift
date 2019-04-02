//
//  DownloadKey.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 22/02/2018.
//

import Foundation
import Vapor
import Fluent
import FluentPostgreSQL
import ApiCore


public typealias DownloadKeys = [DownloadKey]


final public class DownloadKey: DbCoreModel {
    
    public struct Public: Content {
        let appId: DbIdentifier
        let userId: DbIdentifier
        var token: String
        let plist: String
        let file: String
        let ios: String
        
        init(app: App, downloadKey: DownloadKey, request req: Request) {
            token = downloadKey.token
            
            guard let appId = app.id else {
                fatalError("App has to have an Id!")
            }
            
            enum URLType: String {
                case file
                case plist
            }
            
            func urlBuilder(type: URLType) -> String {
                let ext = type == .plist ? "plist" : app.platform.fileExtension
                let url = req.serverURL()
                    .appendingPathComponent("apps")
                    .appendingPathComponent(appId.uuidString)
                    .appendingPathComponent(type.rawValue)
                    .appendingPathComponent(downloadKey.token)
                    .appendingPathComponent(app.fileName.stripExtension())
                    .appendingPathExtension(ext).absoluteString
                return url
            }
            
            plist = urlBuilder(type: .plist)
            file = urlBuilder(type: .file)
            ios = "itms-services://?action=download-manifest&url=\(plist.encodeURLforUseAsQuery())"
            userId = downloadKey.userId
            self.appId = appId
        }
        
        enum CodingKeys: String, CodingKey {
            case appId = "app_id"
            case userId = "user_id"
            case token
            case plist
            case file
            case ios
        }
    }
    
    public var id: DbIdentifier?
    public var appId: DbIdentifier
    public var userId: DbIdentifier
    public var token: String
    public var added: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case appId = "app_id"
        case userId = "user_id"
        case token
        case added
    }
    
    public init(id: DbIdentifier? = nil, appId: DbIdentifier, userId: DbIdentifier) {
        self.id = id
        self.appId = appId
        self.userId = userId
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
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \.id, isIdentifier: true)
            schema.field(for: \.appId)
            schema.field(for: \.userId)
            schema.field(for: \.token, type: .varchar(64))
            schema.field(for: \.added)
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(DownloadKey.self, on: connection)
    }
    
}
