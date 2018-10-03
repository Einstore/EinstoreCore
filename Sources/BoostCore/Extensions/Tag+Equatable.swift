//
//  Tag+Equatable.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 06/03/2018.
//

import Foundation
import ApiCore


extension Tag: Equatable {
    
    public static func ==(lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id && lhs.identifier == rhs.identifier
    }
    
}


extension Array where Element == Tag {
    
    public var ids: [DbIdentifier] {
        let all: [Tag] = filter { $0.id != nil }
        return all.compactMap { $0.id }
    }
    
    public var identifiers: [String] {
        return compactMap { $0.identifier }
    }
    
    public func contains(id: DbIdentifier) -> Bool {
        return ids.contains(id)
    }
    
    public func contains(identifier: String) -> Bool {
        return identifiers.contains(identifier)
    }
    
}
