//
//  Application+Testable.swift
//  EinstoreCoreTestTools
//
//  Created by Ondrej Rafaj on 27/02/2018.
//

import Foundation
@_exported @testable import ApiCore
@_exported @testable import EinstoreCore
import Vapor
import VaporTestTools
import ApiCoreTestTools


extension TestableProperty where TestableType: Application {
    
    public static func newBoostTestApp() -> Application {
        let app = newApiCoreTestApp({ (config, env, services) in
            Env.print()
            try! EinstoreCoreBase.configure(&config, &env, &services)
        }) { (router) in
            
        }
        return app
    }
    
}
