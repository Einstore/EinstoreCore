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
            var boostConfig = BoostConfig()
            boostConfig.storageFileConfig.mainFolderPath = "/tmp/BoostTests/persistent"
            boostConfig.tempFileConfig.mainFolderPath = "/tmp/BoostTests/temporary"
            
            _ = ApiCore.configuration
            ApiCore._configuration?.database.user = "test"
            ApiCore._configuration?.database.database = "boost-test"
            
            try! Boost.configure(boostConfig: &boostConfig, &config, &env, &services)
        }) { (router) in
            try? Boost.boot(router: router)
        }
        return app
    }
    
}
