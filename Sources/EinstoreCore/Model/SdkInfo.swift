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
    let sdk: String
    let language: String?
    let os: String
    let osVersion: String
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case version
        case build
        case created
        case sdk
        case language
        case os
        case osVersion = "os_version"
    }
    
}
