//
//  Model+RawSQL.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 02/04/2018.
//

import Foundation
import Vapor
import Fluent
import FluentPostgreSQL
import PostgreSQL
import DbCore
import ErrorsCore


public protocol Entity: Content {
    static var entity: String { get }
}


extension Entity {

    /// Allows you to run raw queries in a model type.
    /// The data from the query is decoded to the type the method is called on.
    ///
    /// - Parameters:
    ///   - query: The query to run on the database.
    ///   - parameters: Replacement values for `?` placeholders in the query.
    ///   - connector: The object to create a connection to the database with.
    /// - Returns: An array of model instances created from the fetched data, wrapped in a future.
    static func raw(_ query: String, with parameters: [PostgreSQLDataConvertible] = [], on connector: PostgreSQLConnection) throws -> Future<[Self]> {
        return try connector.query(query).map(to: [Self].self) { data in
            return try data.map({ row -> Self in
                let genericData: [QueryField: PostgreSQLData] = row.reduce(into: [:]) { (row, cell) in
                    row[QueryField(name: cell.key.name)] = cell.value
                }
                print(genericData)
                throw ErrorsCore.HTTPError.notFound
                //return try QueryDataDecoder(PostgreSQLDatabase.self, entity: entity).decode(Self.self, from: genericData)
            })
        }
    }

}
