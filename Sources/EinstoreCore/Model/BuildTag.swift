//
//  BuildTag.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 13/02/2018.
//

import Foundation
import Fluent
import ApiCore
import Vapor


/// Join table between Apps and Tags
public final class BuildTag: ModifiablePivot, DbCoreModel {
    
    public typealias Left = Build
    public typealias Right = Tag
    
    public static var leftIDKey: WritableKeyPath<BuildTag, DbIdentifier> {
        return \.buildId
    }
    
    public static var rightIDKey: WritableKeyPath<BuildTag, DbIdentifier> {
        return \.tagId
    }
    
    public var id: DbIdentifier?
    public var buildId: DbIdentifier
    public var tagId: DbIdentifier
    
    enum CodingKeys: String, CodingKey {
        case id = "join_id"
        case buildId = "build_id"
        case tagId = "tag_id"
    }
    
    // MARK: Initialization
    
    public init(_ left: BuildTag.Left, _ right: BuildTag.Right) throws {
        buildId = try left.requireID()
        tagId = try right.requireID()
    }
    
}

// MARK: - Migrations

extension BuildTag: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \BuildTag.id, isIdentifier: true)
            schema.field(for: \BuildTag.buildId)
            schema.field(for: \BuildTag.tagId)
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(BuildTag.self, on: connection)
    }
}
