//
//  ApiKeysManager.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 22/05/2019.
//

import Foundation
import ApiCore
import Fluent


public class ApiKeysManager {
    
    public static func check(nameExists name: String, type: ApiKey.TokenType, teamId: DbIdentifier, except meId: DbIdentifier? = nil, on conn: DatabaseConnectable) -> EventLoopFuture<Bool> {
        let q = ApiKey.query(on: conn).filter(\ApiKey.name == name).filter(\ApiKey.type == type).filter(\ApiKey.teamId == teamId)
        if let meId = meId {
            q.filter(\ApiKey.id != meId)
        }
        return q.count().map() { count in
            return count > 0
        }
    }
    
}
