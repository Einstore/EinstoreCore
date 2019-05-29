//
//  Install.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 15/03/2018.
//

import Foundation
import Vapor
import ApiCore


class Install {
    
    static func make(on connection: ApiCoreConnection) throws -> Future<Void> {
        return [
            Setting(name: "style_primary_action_color", config: "#FF0000").save(on: connection).flatten(),
            Setting(name: "style_primary_action_background_color", config: "").save(on: connection).flatten()
            ].flatten(on: connection)
    }
    
}
