//
//  AppTag.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 13/02/2018.
//

import Foundation
import Fluent
import ApiCore
import Vapor


/// Join table between Apps and Tags
public final class AppTag: ModifiablePivot, DbCoreModel {
    
    public typealias Left = App
    public typealias Right = Tag
    
    public static var leftIDKey: WritableKeyPath<AppTag, DbIdentifier> {
        return \.appId
    }
    
    public static var rightIDKey: WritableKeyPath<AppTag, DbIdentifier> {
        return \.tagId
    }
    
    public var id: DbIdentifier?
    public var appId: DbIdentifier
    public var tagId: DbIdentifier
    
    // MARK: Initialization
    
    public init(_ left: AppTag.Left, _ right: AppTag.Right) throws {
        appId = try left.requireID()
        tagId = try right.requireID()
    }
    
}

// MARK: - Migrations

extension AppTag: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \AppTag.id, isIdentifier: true)
            schema.field(for: \AppTag.appId)
            schema.field(for: \AppTag.tagId)
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(AppTag.self, on: connection)
    }
}
