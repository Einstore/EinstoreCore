//
//  Configuration.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 22/05/2018.
//

import Foundation
import ApiCore


/// Boost configuration
/// For base config look at ApiCore.Configuration
public class Configuration: Configurable {
    
    /// Boost filesystem settings
    public class Filesystem: Codable {
        
        /// Root temp folder path
        public internal(set) var rootTempPath: String
        
        /// Destination path for apps and their assets
        /// - For S3 it will be path after the domain/bucket
        /// - For local filesystem an absolute folder path
        public internal(set) var appDestinationPath: String
        
    }
    
    /// Filesystem
    public internal(set) var filesystem: Filesystem
    
}


extension BoostCore.Configuration {
    
    /// Update from environmental variables
    public func loadEnv() {
        // Root
        load("boostcore.filesystem.root_temp_path", to: &filesystem.rootTempPath)
        load("boostcore.filesystem.app_destination_path", to: &filesystem.appDestinationPath)
    }
    
}
