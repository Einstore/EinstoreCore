//
//  RequestSort.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 23/04/2019.
//

import Foundation
import SQL


/// Object holding main sort data
struct RequestSort: Codable {
    let sort: String?
}

extension RequestSort {
    
    var value: String? {
        guard let first = sort?.split(separator: ":").first?.lowercased() else {
            return nil
        }
        return String(first)
    }
    
    var direction: GenericSQLDirection {
        guard let parts = sort?.split(separator: ":"), parts.count == 2, let last = parts.last?.lowercased() else {
            return .ascending
        }
        if last == "desc" || last == "descending" {
            return .descending
        } else {
            return .ascending
        }
    }
    
}
