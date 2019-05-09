//
//  AppTestCaseSetup.swift
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
import NIO


public protocol AppTestCaseSetup: ApiKeyTestCaseSetup {
    var app1: Build! { get set }
    var app2: Build! { get set }
}


extension AppTestCaseSetup {
    
    var demoUrl: URL {
        let config = DirectoryConfig.detect()
        var url: URL = URL(fileURLWithPath: config.workDir).appendingPathComponent("Resources")
        url.appendPathComponent("apps")
        return url
    }
    
    public func setupApps() {
        clearApps()
        setupApiKeys()
        
        app1 = Build.testable.create(team: team1, name: "App 1", version: "1.2.3", build: "123456", platform: .ios, on: app)
        app1.testable.addTag(name: "common tag", team: team1, identifier: "common-tag", on: app)
        app1.testable.addTag(name: "tag for app 1", team: team1, identifier: "tag-for-app-1", on: app)
        
//        fatalError("Fix with FileCore")
//        _ = try! EinstoreCoreBase.storageFileHandler.createFolderStructure(url: app1.targetFolderPath!, on: app.testable.fakeRequest()).wait()
        
        app2 = Build.testable.create(team: team2, name: "App 2", identifier: "app2", version: "3.2.1", build: "654321", platform: .android, on: app)
        app2.testable.addTag(name: "common tag", team: team1, identifier: "common-tag", on: app)
        app2.testable.addTag(name: "tag for app 2", team: team1, identifier: "tag-for-app-2", on: app)
        
        for x in 0...3 {
            for i in 0...6 {
                Build.testable.create(team: team1, name: "App ios \(i)", version: "1.\(x).\(i)", build: "\((1000 + i))", platform: .ios, on: app)
            }
            
            for i in 0...6 {
                Build.testable.create(team: team1, name: "App android \(i)", version: "1.\(x).\(i)", build: "\((1000 + i))", platform: .android, on: app)
            }
        }
        
        for i in 0...6 {
            let a = Build.testable.create(team: team2, name: "App android \(i)", identifier: "android-app-on-team-2", version: "2.0.\(i)", build: "\((1000 + i))", platform: .android, on: app)
            a.testable.addTag(name: "common tag", team: team1, identifier: "common-tag", on: app)
            a.testable.addTag(name: "tag for app 2", team: team1, identifier: "tag-for-app-2", on: app)
        }
    }
    
    public func deleteAllFiles() {
//        try! Boost.storageFileHandler.delete(path: Boost.config.storageFileConfig.mainFolderPath)
//        try! Boost.storageFileHandler.delete(path: Boost.config.tempFileConfig.mainFolderPath)
    }
    
    public func clearApps() {
        app.testable.delete(allFor: Cluster.self)
        app.testable.delete(allFor: Build.self)
        app.testable.delete(allFor: Tag.self)
        app.testable.delete(allFor: BuildTag.self)
    }
    
}

