//
//  Download.swift
//  BoostCore
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
    
    public var id: DbIdentifier?
    public var appId: DbIdentifier
    public var created: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case appId = "app_id"
        case created
    }
    
    public init(id: DbIdentifier? = nil, appId: DbIdentifier) {
        self.id = id
        self.appId = appId
        self.created = Date()
    }
    
}

// MARK: - Relationships

extension Download {
    
    var app: Parent<Download, App> {
        return parent(\Download.appId)
    }
    
}

// MARK: - Migrations

extension Download: Migration {
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(Download.self, on: connection)
    }
    
}
