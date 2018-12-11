//
//  AppQuery.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 11/12/2018.
//

import Foundation
import Vapor


/// Basic URL query object
public struct AppQuery: Codable {
    
    /// Tags
    public let tags: [String]?
    
}


extension QueryContainer {
    
    /// Query values for app related url values
    public var app: AppQuery {
//        guard let decoded = try? decode(AppQuery.self) else {
//            fatalError("All values in AppQuery have to be optional, are they?!!!")
//        }
//        return decoded
        
        let query = try? decode([String: String].self)
        return AppQuery(tags: query?["tags"]?.split(separator: "|").map({ String($0) }))
    }
    
}

