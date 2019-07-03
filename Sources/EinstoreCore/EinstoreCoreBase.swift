//
//  EinstoreCoreBase.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 12/12/2017.
//

import Foundation
import Vapor
import ApiCore
import ErrorsCore
import Fluent
import FluentPostgreSQL
import MailCore


/// Base class for EinstoreCore
public class EinstoreCoreBase {
    
    /// Registered controllers
    static var controllers: [Controller.Type] = [
        EinstoreController.self,
        TagsController.self,
        AppsController.self,
        ApiKeyController.self,
        ConfigurationController.self,
        SdkController.self
    ]
    
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
    
    /// Configuration cache
    static var _configuration: EinstoreCore.Configuration?
    
    /// Main system configuration
    public static var configuration: EinstoreCore.Configuration {
        get {
            if _configuration == nil {
                _configuration = EinstoreCore.Configuration.default
                _configuration?.loadEnv()
            }
            guard let configuration = _configuration else {
                fatalError("Configuration couldn't be loaded!")
            }
            return configuration
        }
    }
    
    /// Main Vapor configuration method
    public static func configure(_ config: inout Vapor.Config, _ env: inout Vapor.Environment, _ services: inout Services) throws {
        // Override original default logo from ApiCore
        EinstoreLogo.overrideOriginal()
        
        // Add EinstoreCore models to the migrations
        ApiCoreBase.add(model: Cluster.self, database: .db)
        ApiCoreBase.add(model: Build.self, database: .db)
        ApiCoreBase.add(model: DownloadKey.self, database: .db)
        ApiCoreBase.add(model: Tag.self, database: .db)
        ApiCoreBase.add(model: BuildTag.self, database: .db)
        ApiCoreBase.add(model: UsedTag.self, database: .db)
        ApiCoreBase.add(model: ApiKey.self, database: .db)
        ApiCoreBase.add(model: Config.self, database: .db)
        ApiCoreBase.add(model: Download.self, database: .db)
        ApiCoreBase.add(model: ApiKeyTag.self, database: .db)
        ApiCoreBase.add(model: Setting.self, database: .db)
        
        // Register controllers
        for c in controllers {
            ApiCoreBase.controllers.append(c)
        }
        
        // Custom migrations
        ApiCoreBase.migrationConfig.add(migration: BaseMigration.self, database: .db)
        
        // Setup ApiCore
        try ApiCoreBase.configure(&config, &env, &services)
        
        // Verify all has been setup properly
        FlightCheck.tick()
    }
    
}
