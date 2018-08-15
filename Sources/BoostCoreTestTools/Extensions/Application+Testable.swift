//
//  Application+Testable.swift
//  BoostCoreTestTools
//
//  Created by Ondrej Rafaj on 27/02/2018.
//

import Foundation
@_exported @testable import ApiCore
@_exported @testable import BoostCore
import Vapor
import VaporTestTools
import ApiCoreTestTools
import DbCore


extension TestableProperty where TestableType: Application {
    
    public static func newBoostTestApp() -> Application {
        let app = newApiCoreTestApp({ (config, env, services) in
            Env.print()
            try! BoostCoreBase.configure(&config, &env, &services)
        }) { (router) in
            try? BoostCoreBase.boot(router: router)
        }
        return app
    }
    
}
