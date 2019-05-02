//
//  ApiKeyController.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 17/01/2018.
//

import Foundation
import Vapor
import ApiCore
import Fluent
import FluentPostgreSQL
import ErrorsCore


class ApiKeyController: Controller {
    
    static func boot(router: Router, secure: Router, debug: Router) throws {
        secure.get("keys") { (req) -> Future<[ApiKey.Display]> in
            return try req.me.teams().flatMap(to: [ApiKey.Display].self) { teams in
                return ApiKey.query(on: req).filter(\ApiKey.teamId ~~ teams.ids).decode(ApiKey.Display.self).all()
            }
        }
        
        secure.get("teams", DbIdentifier.parameter, "keys") { (req) -> Future<[ApiKey.Display]> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: [ApiKey.Display].self) { team in
                guard let teamId = team.id else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return ApiKey.query(on: req).filter(\ApiKey.teamId == teamId).decode(ApiKey.Display.self).all()
            }
        }
        
        secure.get("keys", DbIdentifier.parameter) { (req) -> Future<ApiKey.Display> in
            let keyId = try req.parameters.next(DbIdentifier.self)
            return ApiKey.find(keyId, on: req).flatMap(to: ApiKey.Display.self) { key in
                guard let key = key else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try req.me.verifiedTeam(id: key.teamId).map(to: ApiKey.Display.self) { team in
                    return key.asDisplay()
                }
            }
        }
        
        secure.post("teams", DbIdentifier.parameter, "keys") { (req) -> Future<Response> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap(to: Response.self) { team in
                guard let teamId = team.id else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try req.content.decode(ApiKey.New.self).flatMap(to: Response.self) { newKey in
                    let key = ApiKey(new: newKey, teamId: teamId)
                    let tokenCache = key.token
                    key.token = try tokenCache.sha()
                    return key.save(on: req).flatMap(to: Response.self) { key in
                        key.token = tokenCache
                        return try key.asResponse(.created, to: req)
                    }
                }
            }
        }
        
        secure.put("keys", DbIdentifier.parameter) { (req) -> Future<ApiKey.Display> in
            let keyId = try req.parameters.next(DbIdentifier.self)
            return ApiKey.find(keyId, on: req).flatMap(to: ApiKey.Display.self) { key in
                guard let key = key else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try req.me.verifiedTeam(id: key.teamId).flatMap(to: ApiKey.Display.self) { team in
                    return try req.content.decode(ApiKey.New.self).flatMap(to: ApiKey.Display.self) { newKey in
                        key.name = newKey.name
                        key.expires = newKey.expires
                        return key.save(on: req).map(to: ApiKey.Display.self) { key in
                            return key.asDisplay()
                        }
                    }
                }
            }
        }
        
        secure.delete("keys", DbIdentifier.parameter) { (req) -> Future<Response> in
            let keyId = try req.parameters.next(DbIdentifier.self)
            return ApiKey.find(keyId, on: req).flatMap(to: Response.self) { key in
                guard let key = key else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try req.me.verifiedTeam(id: key.teamId).flatMap(to: Response.self) { team in
                    return key.delete(on: req).map(to: Response.self) { _ in
                        return try req.response.deleted()
                    }
                }
            }
        }
    }
    
}
