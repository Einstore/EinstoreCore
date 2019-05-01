//
//  ApiKeyTestCaseSetup.swift
//  EinstoreCoreTestTools
//
//  Created by Ondrej Rafaj on 05/03/2018.
//

import Foundation
import XCTest
import Vapor
import Fluent
import VaporTestTools
import FluentTestTools
import ApiCoreTestTools
@testable import ApiCore
@testable import EinstoreCore


public protocol ApiKeyTestCaseSetup: TeamsTestCase {
    var key1: ApiKey! { get set }
    var key2: ApiKey! { get set }
    var key3: ApiKey! { get set }
    var key4: ApiKey! { get set }
    
    var team4: Team! { get set }
}


extension ApiKeyTestCaseSetup {
    
    public func setupApiKeys() {
        app.testable.delete(allFor: ApiKey.self)
        
        setupTeams()
        
        key1 = ApiKey.testable.create(name: "key1", team: team1, on: app)
        key2 = ApiKey.testable.create(name: "key2", team: team1, on: app)
        key3 = ApiKey.testable.create(name: "key3", team: team2, on: app)
        
        let req = app.testable.fakeRequest()
        team4 = Team.testable.create("team 4", on: app)
        _ = try! team4.users.attach(user1, on: req).wait()
        
        key4 = ApiKey.testable.create(name: "key4", team: team4, on: app)
        
    }
    
}

