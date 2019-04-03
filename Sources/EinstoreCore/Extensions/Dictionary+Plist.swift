//
//  Dictionary+Plist.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 15/01/2018.
//

import Foundation
import Vapor
//#if os(Linux)
import SwiftShell
//#endisf


extension Dictionary where Key == String {
    
    static func fill(fromPlist url: URL) throws -> [String: Any]? {
        var format: PropertyListSerialization.PropertyListFormat = .binary
        let plistData: Data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: &format) as? [String: Any]
        return plist
    }
    
}

