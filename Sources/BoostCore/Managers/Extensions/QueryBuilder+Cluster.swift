//
//  QueryBuilder+Cluster.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 08/12/2018.
//

import Foundation
import ApiCore
import Vapor
import Fluent
import FluentPostgreSQL


extension QueryBuilder where Result == Cluster, Database == ApiCoreDatabase {
    
    /// Set filters
    func clusterFilters(on req: Request) throws -> QueryBuilder<ApiCoreDatabase, Result> {
        var s: QueryBuilder<ApiCoreDatabase, Result> = try paginate(on: req)
        
        // Basic search
        if let search = req.query.search, !search.isEmpty {
            s = s.group(.or) { or in
                or.filter(\Cluster.latestAppName, "~~*", search)
                or.filter(\Cluster.identifier, "~~*", search)
            }
        }
        
        let query = try req.query.decode(RequestFilters.self)
        
        // Platform
        if let platform = query.platform {
            s = s.filter(\Cluster.platform == platform)
        }
        
        // Identifier
        if let identifier = query.identifier {
            s = s.filter(\Cluster.identifier, "~~*", identifier)
        }
        
        return s
    }
    
}
