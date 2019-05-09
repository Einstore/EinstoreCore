//
//  Download.swift
//  EinstoreCore
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
    public var buildId: DbIdentifier
    public var userId: DbIdentifier
    public var created: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case buildId = "build_id"
        case userId = "user_id"
        case created
    }
    
    public init(id: DbIdentifier? = nil, buildId: DbIdentifier, userId: DbIdentifier) {
        self.id = id
        self.buildId = buildId
        self.userId = userId
        self.created = Date()
    }
    
}

// MARK: - Relationships

extension Download {
    
    var app: Parent<Download, Build> {
        return parent(\Download.buildId)
    }
    
    var user: Parent<Download, User> {
        return parent(\Download.userId)
    }
    
}

// MARK: - Migrations

extension Download: Migration {
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(Download.self, on: connection)
    }
    
}
