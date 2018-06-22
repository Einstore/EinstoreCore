//
//  BoostCoreBase.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 12/12/2017.
//

import Foundation
import Vapor
import ApiCore
import ErrorsCore
import Fluent
import FluentPostgreSQL
import DbCore
import SettingsCore
import MailCore


/// Base class for BoostCore
public class BoostCoreBase {
    
    /// Registered controllers
    static var controllers: [Controller.Type] = [
        BoostController.self,
        TagsController.self,
        AppsController.self,
        UploadKeyController.self,
        ConfigurationController.self
    ]
    
    /// Boot sequence
    public static func boot(router: Router) throws {
        try ApiCoreBase.boot(router: router)
        try SettingsCore.boot(router: router)
        
        for c in controllers {
            try c.boot(router: router)
        }
    }
    
    /// Private temp file handler
    private static var _tempFileHandler: FileHandler?
    
    /// Temp file handler
    public static var tempFileHandler: FileHandler {
        get {
            if let handler = _tempFileHandler {
                return handler
            }
            let handler = LocalFileHandler()
            _tempFileHandler = handler
            return handler
        }
        set {
            _tempFileHandler = newValue
        }
    }
    
    public static func configure(_ config: inout Vapor.Config, _ env: inout Vapor.Environment, _ services: inout Services) throws {
        ApiAuthMiddleware.allowedGetUri.append("/apps/plist")
        ApiAuthMiddleware.allowedGetUri.append("/apps/file")
        ApiAuthMiddleware.allowedPostUri.append("/apps")
        
        DbCore.add(model: Cluster.self, database: .db)
        DbCore.add(model: App.self, database: .db)
        DbCore.add(model: DownloadKey.self, database: .db)
        DbCore.add(model: Tag.self, database: .db)
        DbCore.add(model: AppTag.self, database: .db)
        DbCore.add(model: UploadKey.self, database: .db)
        DbCore.add(model: Config.self, database: .db)
        
        try SettingsCore.configure(&config, &env, &services)
        
        try ApiCoreBase.configure(&config, &env, &services)
        
        ApiCoreBase.installFutures.append({ req in
            return try Install.make(on: req)
        })
    }
    
}
