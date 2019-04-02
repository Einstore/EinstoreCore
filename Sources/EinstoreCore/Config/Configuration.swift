//
//  Configuration.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 22/05/2018.
//

import Foundation
import ApiCore


/// Einstore configuration
/// For base config look at ApiCore.Configuration
public class Configuration: Configurable {
    
    /// Einstore filesystem settings
    public class Storage: Codable {
        
        /// Root temp folder path (default /tmp/Boost)
        public internal(set) var rootTempPath: String
        
        /// Destination path for apps and their assets
        /// - For S3 it will be path after the domain/bucket
        /// - For local filesystem an absolute folder path
        public internal(set) var appDestinationPath: String
        
        /// Initializer
        init(rootTempPath: String, appDestinationPath: String) {
            self.rootTempPath = rootTempPath
            self.appDestinationPath = appDestinationPath
        }
        
        enum CodingKeys: String, CodingKey {
            case rootTempPath = "root_temp_path"
            case appDestinationPath = "app_destination_path"
        }
        
    }
    
    /// Filesystem
    public internal(set) var storage: Storage
    
    /// Initializer
    init(storage: Storage) {
        self.storage = storage
    }
    
}


extension EinstoreCore.Configuration {
    
    /// Update from environmental variables
    public func loadEnv() {
        // Root
        load("boostcore.storage.root_temp_path", to: &storage.rootTempPath)
        load("boostcore.storage.app_destination_path", to: &storage.appDestinationPath)
    }
    
}
