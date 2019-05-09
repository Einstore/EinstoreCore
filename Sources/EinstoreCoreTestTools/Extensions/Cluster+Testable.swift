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
@testable import EinstoreCore
import VaporTestTools


extension TestableProperty where TestableType == Cluster {
    
    @discardableResult public static func guaranteedCluster(identifier: String, platform: Build.Platform, on app: Application) -> Cluster {
        let req = app.testable.fakeRequest()
        if let cluster = try! Cluster.query(on: req).filter(\Cluster.identifier == identifier).filter(\Cluster.platform == platform).first().wait() {
            return cluster
        } else {
            let build = Build(teamId: UUID(),clusterId: UUID(), name: identifier, identifier: identifier, version: "", build: "", platform: platform, built: Date(), size: 0, sizeTotal: 0)
            let object = Cluster(latestBuild: build, appCount: 0)
            return try! object.save(on: req).wait()
        }
    }
    
    @discardableResult public static func cluster(withId id: DbIdentifier, on app: Application) -> Cluster {
        let req = app.testable.fakeRequest()
        let cluster = try! Cluster.query(on: req).filter(\Cluster.id == id).first().wait()
        return cluster!
    }
    
}

