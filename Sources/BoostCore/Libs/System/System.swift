//
//  System.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 07/08/2018.
//

import Foundation
import Vapor


/// System methods and paths
public class System {
    
    /// Defualt singleton accessor
    public static let `default` = System()
    
    /// System bin URL (which contains all commandline utilities)
    var binUrl: URL {
        let config = DirectoryConfig.detect()
        var url: URL = URL(fileURLWithPath: config.workDir).appendingPathComponent("Resources")
        url.appendPathComponent("bin")
        return url
    }
    
}
