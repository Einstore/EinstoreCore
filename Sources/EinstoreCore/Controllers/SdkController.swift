//
//  SdkController.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 01/05/2019.
//

import Foundation
import ApiCore
import Vapor


class SdkController: Controller {
    
    static func boot(router: Router, secure: Router, debug: Router) throws {
        router.post("sdk") { (req) -> EventLoopFuture<SdkInfo> in
            return try req.content.decode(SdkInfo.self).flatMap({ info in
                return req.eventLoop.newSucceededFuture(result: info)
            })
        }
    }
    
}
