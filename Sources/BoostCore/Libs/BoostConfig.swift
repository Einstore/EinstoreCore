//
//  BoostConfig.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 08/02/2018.
//

import Foundation
import DbCore
import Fluent
import MailCore


public struct BoostConfig {
    
    public var tempFileConfig = TempFileConfig()
    public var storageFileConfig = StorageFileConfig()
    
    public init() {
        
    }
    
}
