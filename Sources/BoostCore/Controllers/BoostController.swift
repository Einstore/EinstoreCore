//
//  BoostController.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 01/04/2018.
//

import Foundation
import Vapor
import ErrorsCore
import ApiCore


public class BoostController: Controller {

    public static func boot(router: Router) throws {
        router.get("info") { req -> Future<Response> in
            let info: [String: String] = [
                "name": Environment.get("BOOST_NAME") ?? "Boost",
                "url": req.serverURL().absoluteString
            ]
            let response = try info.asJson().asResponse(.ok, to: req)
            return response
        }
    }
    
}
