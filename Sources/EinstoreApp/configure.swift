import Foundation
import Vapor
import EinstoreCore
import ApiCore
import MailCore


public func configure(_ config: inout Vapor.Config, _ env: inout Vapor.Environment, _ services: inout Vapor.Services) throws {
    print("Starting Boost")
    Env.print()
    
    // Configure BoostCore
    try BoostCoreBase.configure(&config, &env, &services)
    
    // Register routes
    let router = EngineRouter.default()
    try ApiCoreBase.boot(router: router)
    services.register(router, as: Router.self)
}
