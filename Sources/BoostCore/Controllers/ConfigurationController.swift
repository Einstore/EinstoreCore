//
//  ConfigurationController.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 11/04/2018.
//

import Foundation
import Vapor
import ApiCore
import Fluent
import FluentPostgreSQL


class ConfigurationController: Controller {
    
    static func boot(router: Router, secure: Router, debug: Router) throws {
        router.get("teams", DbIdentifier.parameter, "config") { (req) -> Future<Config> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: Config.self) { team in
                return try guaranteedConfig(for: teamId, on: req)
            }
        }
        
        secure.post("teams", DbIdentifier.parameter, "config") { (req) -> Future<Config> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.content.decode(Config.self).flatMap(to: Config.self) { data in
                return try req.me.verifiedTeam(id: teamId).flatMap(to: Config.self) { team in
                    return try guaranteedConfig(for: teamId, on: req).flatMap(to: Config.self) { configuration in
                        configuration.teamId = teamId
                        configuration.theme = data.theme
                        return configuration.save(on: req)
                    }
                }
            }
        }
    }
    
}


extension ConfigurationController {
    
    private static func guaranteedConfig(for teamId: DbIdentifier, on req: Request) throws -> Future<Config> {
        return Config.query(on: req).filter(\Config.teamId == teamId).first().map(to: Config.self) { configuration in
            guard let configuration = configuration else {
                let theme = Config.Theme(
                    primaryColor: "000000",
                    primaryBackgroundColor: "FFFFFF",
                    primaryButtonColor: "FFFFFF",
                    primaryButtonBackgroundColor: "E94F91"
                )
                return Config(teamId: teamId, theme: theme)
            }
            return configuration
        }
    }
    
}
