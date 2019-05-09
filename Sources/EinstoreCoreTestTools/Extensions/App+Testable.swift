//
//  App+Testable.swift
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


extension TestableProperty where TestableType == Build {
    
    @discardableResult public static func create(team: Team, name: String, identifier: String? = nil, version: String, build: String, platform: Build.Platform, on app: Application) -> Build {
        let req = app.testable.fakeRequest()
        let identifier = (identifier ?? name.safeText)
        let cluster = Cluster.testable.guaranteedCluster(identifier: identifier, platform: platform, on: app)
        cluster.teamId = team.id!
        let object = Build(teamId: team.id!, clusterId: cluster.id!, name: name, identifier: identifier, version: version, build: build, platform: platform, built: Date(), size: 5000, sizeTotal: 5678)
        cluster.buildCount += 1
        _ = try! cluster.add(build: object, on: req).wait()
        _ = try! cluster.save(on: req).wait()
        return try! object.save(on: req).wait()
    }
    
    public func addTag(name: String, team: Team, identifier: String, on app: Application) {
        let req = app.testable.fakeRequest()
        let tag = try! Tag(teamId: team.id!, identifier: "tag-for-app-1").save(on: req).wait()
        _  = try! element.tags.attach(tag, on: req).wait()
    }
    
}

