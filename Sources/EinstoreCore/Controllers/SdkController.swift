//
//  SdkController.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 01/05/2019.
//

import Foundation
import ApiCore
import Vapor
import Fluent
import ErrorsCore


class SdkController: Controller {
    
    static func boot(router: Router, secure: Router, debug: Router) throws {
        router.post("sdk") { (req) -> EventLoopFuture<Build> in
            guard let token = req.http.headers.authorizationToken else {
                throw AuthError.authenticationFailed
            }
            return try ApiKey.query(on: req).filter(\ApiKey.token == token.sha()).filter(\ApiKey.type == 1).first().flatMap(to: Build.self) { token in
                guard let token = token else {
                    throw AuthError.authenticationFailed
                }
                return try req.content.decode(SdkInfo.self).flatMap({ info in
                    return Cluster.query(on: req).filter(\Cluster.identifier == info.identifier).filter(\Cluster.platform == info.platform).filter(\Cluster.teamId == token.teamId).first().flatMap(to: Build.self) { cluster in
                        guard let cluster = cluster else {
                            throw ErrorsCore.HTTPError.notFound
                        }
                        
                        return try cluster.builds.query(on: req).sort(\Build.built, .descending).first().map({ build in
                            guard let build = build else {
                                throw ErrorsCore.HTTPError.notFound
                            }
                            return build
                        })
                    }
                })
            }
        }
    }
    
}
