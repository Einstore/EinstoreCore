//
//  ApiKey+Testable.swift
//  EinstoreCoreTestTools
//
//  Created by Ondrej Rafaj on 05/03/2018.
//

import Foundation
import ApiCore
import Vapor
import Fluent
@testable import EinstoreCore
import VaporTestTools


extension TestableProperty where TestableType == ApiKey {
    
    @discardableResult public static func create(name: String, team: Team, expires: Date? = nil, on app: Application) -> ApiKey {
        let req = app.testable.fakeRequest()
        let key = ApiKey(teamId: team.id!, name: name, expires: expires, type: 0)
        let backupToken = key.token
        key.token = try! key.token.sha()
        _ = try! key.save(on: req).wait()
        key.token = backupToken
        return key
    }
    
}
