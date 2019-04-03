//
//  RequestFilters.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 08/12/2018.
//

import Foundation


/// Object holding main filters
struct RequestFilters: Codable {
    let platform: App.Platform?
    let identifier: String?
}
