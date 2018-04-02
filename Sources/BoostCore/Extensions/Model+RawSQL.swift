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

//
//extension Model {
//    
//    /// Allows you to run raw queries in a model type.
//    /// The data from the query is decoded to the type the method is called on.
//    ///
//    /// - Parameters:
//    ///   - query: The query to run on the database.
//    ///   - parameters: Replacement values for `?` placeholders in the query.
//    ///   - connector: The object to create a connection to the database with.
//    /// - Returns: An array of model instances created from the fetched data, wrapped in a future.
//    static func raw(_ query: String, with parameters: [PostgreSQLDataConvertible] = [], on connector: DatabaseConnectable) -> Future<[Self]> {
//        connector.connect(to: .db).flatMap(to: Self.self) { connection in
//            return try connection.query(query, parameters).flatMap(to: Self.self) { data in
//                return try data.map({ row -> Self in
//                    let genericData: [QueryField: MySQLData] = row.reduce(into: [:]) { (row, cell) in
//                        row[QueryField(entity: cell.key.table, name: cell.key.name)] = cell.value
//                    }
//                    return try QueryDataDecoder(MySQLDatabase.self, entity: Self.entity).decode(Self.self, from: genericData)
//                })
//
//            }
//        }
//        // I would document this, but I hope it get Sherlocked by Fluent.
////        return connector.connect(to: .db).flatMap(to: [[PostgreSQLColumn : PostgreSQLData]].self) { (connection) in
////            return connection.query
////            }.map(to: [Self].self, { (data) in
////                return try data.map({ row -> Self in
////                    let genericData: [QueryField: MySQLData] = row.reduce(into: [:]) { (row, cell) in
////                        row[QueryField(entity: cell.key.table, name: cell.key.name)] = cell.value
////                    }
////                    return try QueryDataDecoder(MySQLDatabase.self, entity: Self.entity).decode(Self.self, from: genericData)
////                })
////            }
////        )
//    }
//    
//}
