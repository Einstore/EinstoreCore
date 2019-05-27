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
    
    enum Error: FrontendError {
        
        case nameExists
        
        var status: HTTPStatus {
            return .conflict
        }
        
        var identifier: String {
            return "api_keys.name_exists"
        }
        
        var reason: String {
            return "API key name already exists"
        }
        
    }
    
    static func boot(router: Router, secure: Router, debug: Router) throws {
        secure.get("keys") { (req) -> Future<[ApiKey.Display]> in
            return try req.me.teams().flatMap() { teams in
                return ApiKey.query(on: req).filter(\ApiKey.teamId ~~ teams.ids).decode(ApiKey.Display.self).all()
            }
        }
        
        secure.get("teams", DbIdentifier.parameter, "keys") { (req) -> Future<[ApiKey.Display]> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap() { team in
                guard let teamId = team.id else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return ApiKey.query(on: req).filter(\ApiKey.teamId == teamId).decode(ApiKey.Display.self).all()
            }
        }
        
        secure.get("keys", DbIdentifier.parameter) { (req) -> Future<ApiKey.Display> in
            let keyId = try req.parameters.next(DbIdentifier.self)
            return ApiKey.find(keyId, on: req).flatMap() { key in
                guard let key = key else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try req.me.verifiedTeam(id: key.teamId).map() { team in
                    return key.asDisplay()
                }
            }
        }
        
        
        
        secure.post("teams", DbIdentifier.parameter, "keys") { (req) -> Future<Response> in
            let teamId = try req.parameters.next(DbIdentifier.self)
            return try req.me.verifiedTeam(id: teamId).flatMap() { team in
                guard let teamId = team.id else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try req.content.decode(ApiKey.New.self).flatMap() { newKey in
                    return ApiKeysManager.check(nameExists: newKey.name, type: newKey.type, teamId: teamId, on: req).flatMap() { exists in
                        guard !exists else {
                            throw Error.nameExists
                        }
                        let key = ApiKey(new: newKey, teamId: teamId)
                        let tokenCache = key.token
                        key.token = try tokenCache.sha()
                        return key.save(on: req).flatMap() { key in
                            key.token = tokenCache
                            return try key.asResponse(.created, to: req)
                        }
                    }
                }
            }
        }
        
        secure.put("keys", DbIdentifier.parameter) { (req) -> Future<ApiKey.Display> in
            let keyId = try req.parameters.next(DbIdentifier.self)
            return ApiKey.find(keyId, on: req).flatMap() { key in
                guard let key = key else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try req.me.verifiedTeam(id: key.teamId).flatMap() { team in
                    return try req.content.decode(ApiKey.Update.self).flatMap() { newKey in
                        return ApiKeysManager.check(nameExists: newKey.name, type: key.type, teamId: key.teamId, except: keyId, on: req).flatMap() { exists in
                            guard !exists else {
                                throw Error.nameExists
                            }
                            key.name = newKey.name
                            key.tags = newKey.tags
                            key.checkTags()
                            key.expires = newKey.expires
                            return key.save(on: req).map() { key in
                                return key.asDisplay()
                            }
                        }
                    }
                }
            }
        }
        
        secure.delete("keys", DbIdentifier.parameter) { (req) -> Future<Response> in
            let keyId = try req.parameters.next(DbIdentifier.self)
            return ApiKey.find(keyId, on: req).flatMap() { key in
                guard let key = key else {
                    throw ErrorsCore.HTTPError.notFound
                }
                return try req.me.verifiedTeam(id: key.teamId).flatMap() { team in
                    return key.delete(on: req).map() { _ in
                        return try req.response.deleted()
                    }
                }
            }
        }
    }
    
}
