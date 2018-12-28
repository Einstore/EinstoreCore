//
//  Cluster+Testable.swift
//  ApiCoreTestTools
//
//  Created by Ondrej Rafaj on 24/07/2018.
//

import Foundation
import ApiCore
import Vapor
import Fluent
@testable import BoostCore
import VaporTestTools


extension TestableProperty where TestableType == Cluster {
    
    @discardableResult public static func guaranteedCluster(identifier: String, platform: App.Platform, on app: Application) -> Cluster {
        let req = app.testable.fakeRequest()
        if let cluster = try! Cluster.query(on: req).filter(\Cluster.identifier == identifier).first().wait() {
            return cluster
        } else {
            let app = App(clusterId: UUID(), name: identifier, identifier: identifier, version: "", build: "", platform: platform, size: 0, sizeTotal: 0)
            let object = Cluster(latestApp: app, appCount: 0)
            return try! object.save(on: req).wait()
        }
    }
    
    @discardableResult public static func cluster(withId id: DbIdentifier, on app: Application) -> Cluster {
        let req = app.testable.fakeRequest()
        let cluster = try! Cluster.query(on: req).filter(\Cluster.id == id).first().wait()
        return cluster!
    }
    
}

