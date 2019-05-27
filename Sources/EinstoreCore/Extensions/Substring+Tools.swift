//
//  Substring+Tools.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 27/05/2019.
//

import Foundation


extension Array where Element == Substring {
    
    public func asStrings() -> [String] {
        return map({ String($0) })
    }
    
}
