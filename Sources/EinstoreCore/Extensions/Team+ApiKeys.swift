//
//  Team+ApiKeys.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 05/03/2018.
//

import Foundation
import ApiCore
import Fluent


// MARK: - Relations

extension Team {
    
    public var apiKeys: Children<Team, ApiKey> {
        return children(\.teamId)
    }
    
}

