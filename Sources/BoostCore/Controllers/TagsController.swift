//
//  TagsController.swift
//  App
//
//  Created by Ondrej Rafaj on 09/12/2017.
//

import Foundation
import Vapor
import ApiCore
import Fluent
import FluentPostgreSQL


class TagsController: Controller {
    
    static func boot(router: Router) throws {
        // Tags for an app
        router.get("apps", DbIdentifier.parameter, "tags") { (req) -> Future<Tags> in
            let appId = try req.parameters.next(DbIdentifier.self)
            return try TagsManager.tags(appId: appId, on: req)
        }
        
        router.get("tags") { (req) -> Future<Tags> in
            return req.withPooledConnection(to: .db) { (db) -> Future<Tags> in
                return Tag.query(on: req).all()
            }
        }
    }
    
}
