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
        router.post("sdk") { (req) -> EventLoopFuture<SdkInfo> in
            guard let token = req.http.headers.authorizationToken else {
                throw AuthError.authenticationFailed
            }
            return try ApiKey.query(on: req).filter(\ApiKey.token == token.sha()).filter(\ApiKey.type == 1).first().flatMap(to: SdkInfo.self) { token in
                guard let token = token else {
                    throw AuthError.authenticationFailed
                }
                return try req.content.decode(SdkInfo.self).flatMap({ info in
                    return Cluster.query(on: req).filter(\Cluster.identifier == info.identifier).filter(\Cluster.platform == info.platform).filter(\Cluster.teamId == token.teamId).first().flatMap(to: SdkInfo.self) { cluster in
                        guard let cluster = cluster else {
                            throw ErrorsCore.HTTPError.notFound
                        }
                        
                        // get latest build from the cluster
                        
                        
                        return req.eventLoop.newSucceededFuture(result: info)
                    }
                })
            }
        }
    }
    
}
