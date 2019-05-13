//
//  Data+Tools.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 13/05/2019.
//

import Foundation
import Crypto


extension Data {
    
    public func asMD5String() throws -> String {
        return try MD5.hash(self).hexEncodedString()
    }
    
}
