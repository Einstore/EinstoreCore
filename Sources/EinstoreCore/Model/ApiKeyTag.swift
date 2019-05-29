//
//  ApiKeyTag.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 27/05/2019.
//

import Foundation
import Fluent
import ApiCore
import Vapor


/// Join table between ApiKeys and Tags
public final class ApiKeyTag: ModifiablePivot, DbCoreModel {
    
    public typealias Left = ApiKey
    public typealias Right = Tag
    
    public static var leftIDKey: WritableKeyPath<ApiKeyTag, DbIdentifier> {
        return \.apiKeyId
    }
    
    public static var rightIDKey: WritableKeyPath<ApiKeyTag, DbIdentifier> {
        return \.tagId
    }
    
    public var id: DbIdentifier?
    public var apiKeyId: DbIdentifier
    public var tagId: DbIdentifier
    
    enum CodingKeys: String, CodingKey {
        case id = "akt_join_id"
        case apiKeyId = "apikey_id"
        case tagId = "tag_id"
    }
    
    // MARK: Initialization
    
    public init(_ left: ApiKeyTag.Left, _ right: ApiKeyTag.Right) throws {
        apiKeyId = try left.requireID()
        tagId = try right.requireID()
    }
    
}

// MARK: - Migrations

extension ApiKeyTag: Migration {
    
    public static func prepare(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.field(for: \ApiKeyTag.id, isIdentifier: true)
            schema.field(for: \ApiKeyTag.apiKeyId)
            schema.field(for: \ApiKeyTag.tagId)
        }
    }
    
    public static func revert(on connection: ApiCoreConnection) -> Future<Void> {
        return Database.delete(ApiKeyTag.self, on: connection)
    }
}
