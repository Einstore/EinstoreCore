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
@testable import BoostCore
import VaporTestTools


extension TestableProperty where TestableType == DownloadKey {
    
    @discardableResult public static func create(forAppId appId: DbIdentifier, user: User, on app: Application) -> DownloadKey {
        let req = app.testable.fakeRequest()
        let key = DownloadKey(appId: appId, userId: user.id!)
        let backupToken = key.token
        key.token = try! key.token.sha()
        _ = try! key.save(on: req).wait()
        key.token = backupToken
        return key
    }
    
}
