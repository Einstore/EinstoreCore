//
//  DownloadKey+Testable.swift
//  ApiCoreTestTools
//
//  Created by Ondrej Rafaj on 10/10/2018.
//

import Foundation
import ApiCore
import Vapor
import Fluent
@testable import EinstoreCore
import VaporTestTools


extension TestableProperty where TestableType == DownloadKey {
    
    @discardableResult public static func create(forBuildId buildId: DbIdentifier, user: User, on app: Application) -> DownloadKey {
        let req = app.testable.fakeRequest()
        let key = DownloadKey(buildId: buildId, userId: user.id!)
        let backupToken = key.token
        key.token = try! key.token.sha()
        _ = try! key.save(on: req).wait()
        key.token = backupToken
        return key
    }
    
}
