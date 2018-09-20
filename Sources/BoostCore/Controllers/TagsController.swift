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
        router.get("tags") { (req) -> Future<Tags> in
            return req.withPooledConnection(to: .db) { (db) -> Future<Tags> in
                return Tag.query(on: req).all()
            }
        }
    }
    
}
