//
//  String+Tools.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 31/10/2018.
//

import Foundation
import ApiCore


extension String {
    
    public func encodeURLforUseAsQuery() -> String {
        return addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "?& \n").inverted) ?? "badUrl"
    }
    
    public func stripExtension() -> String {
        guard contains(".") else {
            return self
        }
        var parts = split(separator: ".")
        parts.removeLast()
        return parts.joined(separator: ".")
    }
    
    /// Convert to safe text (convert-to-safe-text)
    public var safeTagText: String {
        var text = components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_.-").inverted).joined(separator: "-").lowercased()
        text = text.components(separatedBy: CharacterSet(charactersIn: "-")).filter { !$0.isEmpty }.joined(separator: "-")
        return text.lowercased()
    }
    
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
}


extension Array where Element == String {
    
    public func safeTagText() -> [String] {
        return map({ $0.safeTagText })
    }
    
}
