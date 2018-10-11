//
//  UploadKey+Testable.swift
//  BoostCoreTestTools
//
//  Created by Ondrej Rafaj on 05/03/2018.
//

import Foundation
import ApiCore
import Vapor
import Fluent
@testable import BoostCore
import VaporTestTools


extension TestableProperty where TestableType == UploadKey {
    
    @discardableResult public static func create(name: String, team: Team, expires: Date? = nil, on app: Application) -> UploadKey {
        let req = app.testable.fakeRequest()
        let key = UploadKey(teamId: team.id!, name: name, expires: expires)
        let backupToken = key.token
        key.token = try! key.token.sha()
        _ = try! key.save(on: req).wait()
        key.token = backupToken
        return key
    }
    
}
