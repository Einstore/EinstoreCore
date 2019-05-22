//
//  SdkInfo.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 01/05/2019.
//

import Foundation
import Vapor


struct SdkInfo: Content {
    
    let identifier: String
    let version: String
    let build: String
    let created: Date
    let sdkVersion: String
    let language: String?
    let platform: Build.Platform
    let osVersion: String
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case version
        case build
        case created
        case sdkVersion = "sdk_version"
        case language
        case platform
        case osVersion = "os_version"
    }
    
}
