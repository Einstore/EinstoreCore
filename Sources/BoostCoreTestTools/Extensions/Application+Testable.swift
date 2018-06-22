//
//  Application+Testable.swift
//  BoostCoreTestTools
//
//  Created by Ondrej Rafaj on 27/02/2018.
//

import Foundation
@testable import ApiCore
import BoostCore
import Vapor
import VaporTestTools
import ApiCoreTestTools
import DbCore


extension TestableProperty where TestableType: Application {
    
    public static func newBoostTestApp() -> Application {
        let app = newApiCoreTestApp({ (config, env, services) in
            _ = ApiCoreBase.configuration
            ApiCoreBase._configuration?.database.user = "test"
            ApiCoreBase._configuration?.database.database = "boost-test"
            
            try! BoostCoreBase.configure(&config, &env, &services)
        }) { (router) in
            try? BoostCoreBase.boot(router: router)
        }
        return app
    }
    
}
