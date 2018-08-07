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
            _ = ApiCoreBase.configuration
            ApiCoreBase._configuration?.database.user = "test"
            ApiCoreBase._configuration?.database.database = "boost-test"
            ApiCoreBase._configuration?.storage.local.root = "/tmp/Boost-testing/"
            ApiCoreBase._configuration?.storage.s3.enabled = false
            
            try! BoostCoreBase.configure(&config, &env, &services)
        }) { (router) in
            try? BoostCoreBase.boot(router: router)
        }
        return app
    }
    
}
