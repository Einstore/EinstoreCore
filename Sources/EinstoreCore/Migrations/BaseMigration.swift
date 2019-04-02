//
//  BaseMigration.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 03/04/2019.
//

import Foundation
import Fluent
import ApiCore


struct BaseMigration: Migration {
    
    typealias Database = ApiCoreDatabase
    
    static func prepare(on conn: ApiCoreConnection) -> EventLoopFuture<Void> {
        return try! Install.make(on: conn)
    }
    
    static func revert(on conn: ApiCoreConnection) -> EventLoopFuture<Void> {
        return conn.eventLoop.newSucceededVoidFuture()
    }
    
}
