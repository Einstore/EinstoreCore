//
//  Boost.swift
//  Boost
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


public class Boost {
    
    public static func boot(_ app: Application) throws {
        
    }
    
    static var controllers: [Controller.Type] = [
        BoostController.self,
        TagsController.self,
        AppsController.self,
        UploadKeyController.self,
        ConfigurationController.self
    ]
    
    public static func boot(router: Router) throws {
        try ApiCore.boot(router: router)
        try SettingsCore.boot(router: router)
        
        for c in controllers {
            try c.boot(router: router)
        }
    }
    
    static var config: BoostConfig!
    
    private static var _tempFileHandler: FileHandler?
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
    
    private static var _storageFileHandler: FileHandler?
    public static var storageFileHandler: FileHandler {
        get {
            if let handler = _storageFileHandler {
                return handler
            }
            let handler = LocalFileHandler()
            _storageFileHandler = handler
            return handler
        }
        set {
            _storageFileHandler = newValue
        }
    }
    
    
    public static func configure(boostConfig: inout BoostConfig, _ config: inout Vapor.Config, _ env: inout Vapor.Environment, _ services: inout Services) throws {
        self.config = boostConfig
        
        ApiAuthMiddleware.allowedGetUri.append("/apps/plist")
        ApiAuthMiddleware.allowedGetUri.append("/apps/file")
        ApiAuthMiddleware.allowedGetUri.append("/info")
        ApiAuthMiddleware.allowedPostUri.append("/apps")
        
        DbCore.migrationConfig.add(model: App.self, database: .db)
        DbCore.migrationConfig.add(model: DownloadKey.self, database: .db)
        DbCore.migrationConfig.add(model: Tag.self, database: .db)
        DbCore.migrationConfig.add(model: AppTag.self, database: .db)
        DbCore.migrationConfig.add(model: UploadKey.self, database: .db)
        DbCore.migrationConfig.add(model: Configuration.self, database: .db)
        
        try SettingsCore.configure(&config, &env, &services)
        
        try ApiCore.configure(&config, &env, &services)
        
        ApiCore.installFutures.append({ req in
            return try Install.make(on: req)
        })
    }
    
}
