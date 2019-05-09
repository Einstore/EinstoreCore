//
//  QueryBuilder+App.swift
//  ApiCore
//
//  Created by Ondrej Rafaj on 08/12/2018.
//

import Foundation
import ApiCore
import Vapor
import Fluent
import FluentPostgreSQL


extension QueryBuilder where Result == Build, Database == ApiCoreDatabase {
    
    /// Set filters
    func appFilters(on req: Request) throws -> QueryBuilder<ApiCoreDatabase, Result> {
        var s: QueryBuilder<ApiCoreDatabase, Result> = try paginate(on: req)
        
        // Basic search
        if let search = req.query.search {
            s = s.group(.or) { or in
                let search = "%\(search)%"
                or.filter(\Build.name, "ILIKE", search)
                or.filter(\Build.identifier, "ILIKE", search)
                or.filter(\Build.version, "ILIKE", search)
                or.filter(\Build.build, "ILIKE", search)
            }
        }
        
        let query = try req.query.decode(RequestFilters.self)
        
        // Platform
        if let platform = query.platform {
            s = s.filter(\Build.platform == platform)
        }
        
        // Identifier
        if let identifier = query.identifier {
            s = s.filter(\Build.identifier, "ILIKE", identifier)
        }
        
        return s
    }
    
    /// Make sure we get only apps belonging to the user
    func safeBuild(id: DbIdentifier, teamIds: [DbIdentifier]) throws -> Self {
        return group(.and) { and in
            and.filter(\Build.id == id)
            and.filter(\Build.teamId ~~ teamIds)
        }
    }
    
}
