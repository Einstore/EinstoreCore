//
//  Team+Tags.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 01/12/2018.
//

import Foundation
import ApiCore
import Fluent


extension Team {
    
    var tags: Siblings<Team, Tag, TeamTag> {
        return siblings()
    }
    
}
