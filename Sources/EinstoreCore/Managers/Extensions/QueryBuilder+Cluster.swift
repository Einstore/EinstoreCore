//
//  QueryBuilder+Cluster.swift
//  EinstoreCore
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
                let search = "%\(search)%"
                or.filter(\Cluster.latestAppName, "ILIKE", search)
                or.filter(\Cluster.identifier, "ILIKE", search)
            }
        }
        
        let query = try req.query.decode(RequestFilters.self)
        
        // Platform
        if let platform = query.platform {
            s = s.filter(\Cluster.platform == platform)
        }
        
        // Identifier
        if let identifier = query.identifier {
            s = s.filter(\Cluster.identifier, "ILIKE", identifier)
        }
        
        return s
    }
    
    /// Set sorting
    func clusterSorting(on req: Request) throws -> QueryBuilder<ApiCoreDatabase, Result> {
        let sort = try req.query.decode(RequestSort.self)
        if let value = sort.value {
            switch true {
            case value == "name":
                return self.sort(\Cluster.latestAppName, sort.direction)
            case value == "date":
                return self.sort(\Cluster.latestAppAdded, sort.direction)
            case value == "count":
                return self.sort(\Cluster.appCount, sort.direction)
            default:
                return self.sort(\Cluster.latestAppAdded, .ascending)
            }
        }
        return self.sort(\Cluster.latestAppAdded, .ascending)
    }
    
}
