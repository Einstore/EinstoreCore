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
    
    /// Conver tags from build info data
    public class TagsFromInfo: Codable {
        
        public internal(set) var enable: Bool
        
        public internal(set) var commit: Bool
        public internal(set) var pr: Bool
        public internal(set) var pm: Bool
        
        /// Initializer
        init(enable: Bool, commit: Bool, pr: Bool, pm: Bool) {
            self.enable = enable
            self.commit = commit
            self.pr = pr
            self.pm = pm
        }
        
    }
    
    /// Filesystem
    public internal(set) var storage: Storage
    
    // Tags form build info
    public internal(set) var tagsFromInfo: TagsFromInfo
    
    /// Demo mode
    public internal(set) var demo: Bool
    
    /// Initializer
    init(storage: Storage, demo: Bool, tagsFromInfo: TagsFromInfo) {
        self.storage = storage
        self.demo = demo
        self.tagsFromInfo = tagsFromInfo
    }
    
}


extension EinstoreCore.Configuration {
    
    public static var `default`: Configuration {
        return Configuration(
            storage: Configuration.Storage(
                rootTempPath: "tmp",
                appDestinationPath: "apps"
            ),
            demo: false,
            tagsFromInfo: TagsFromInfo(
                enable: true,
                commit: true,
                pr: true,
                pm: true
            )
        )
    }
    
    /// Update from environmental variables
    public func loadEnv() {
        // Root
        load("BOOSTCORE_STORAGE_ROOT_TEMP_PATH", to: &storage.rootTempPath)
        load("BOOSTCORE_STORAGE_APP_DESTINATION_PATH", to: &storage.appDestinationPath)
        
        load("BOOSTCORE_DEMO", to: &demo)
        
        load("BOOSTCORE_TAGS_FROM_INFO_ENABLED", to: &tagsFromInfo.enable)
        load("BOOSTCORE_TAGS_FROM_INFO_COMMIT", to: &tagsFromInfo.commit)
        load("BOOSTCORE_TAGS_FROM_INFO_PR", to: &tagsFromInfo.pr)
        load("BOOSTCORE_TAGS_FROM_INFO_PM", to: &tagsFromInfo.pm)
    }
    
}
