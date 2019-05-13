//
//  AppsControllerTests.swift
//  EinstoreCoreTests
//
//  Created by Ondrej Rafaj on 05/03/2018.
//

import Foundation
import XCTest
@testable import Vapor
@testable import NIO
@testable import Service
import VaporTestTools
import FluentTestTools
import ApiCoreTestTools
import EinstoreCoreTestTools
import ErrorsCore
@testable import ApiCore
@testable import EinstoreCore
import PostgreSQL
import FluentPostgreSQL
import MailCore
import MailCoreTestTools
import Crypto


class AppsControllerTests: XCTestCase, AppTestCaseSetup, LinuxTests {
    
    var app: Application!
    
    var user1: User!
    var user2: User!
    
    var adminTeam: Team!
    var team1: Team!
    var team2: Team!
    
    var key1: ApiKey!
    var key2: ApiKey!
    var key3: ApiKey!
    var key4: ApiKey!
    
    var team4: Team!
    
    var app1: Build!
    var app2: Build!
    
    
    // MARK: Linux
    
    static let allTests: [(String, Any)] = [
        ("testGetAppsOverview", testGetAppsOverview),
        ("testGetAppsOverviewSortedByNameAsc", testGetAppsOverviewSortedByNameAsc),
        ("testAppSearch", testAppSearch),
        ("testPartialAppSearch", testPartialAppSearch),
        ("testPartialInsensitiveAppSearch", testPartialInsensitiveAppSearch),
        ("testAppIconIsRetrieved", testAppIconIsRetrieved),
        ("testAppIconIsRetrievedFromLocalStore", testAppIconIsRetrievedFromLocalStore),
        ("testAppTags", testAppTags),
        ("testAuthReturnsValidToken", testAuthReturnsValidToken),
        ("testBadTokenUpload", testBadTokenUpload),
        ("testCantDeleteOtherPeoplesApp", testCantDeleteOtherPeoplesApp),
        ("testDeleteCluster", testDeleteCluster),
        ("testDeleteApp", testDeleteApp),
        ("testDownloadAndroidApp", testDownloadAndroidApp),
        ("testDownloadIosApp", testDownloadIosApp),
        ("testGetApp", testGetApp),
        ("testGetApps", testGetApps),
        ("testLinuxTests", testLinuxTests),
        ("testObfuscatedApkUploadWithJWTAuth", testObfuscatedApkUploadWithJWTAuth),
        ("testAuthReturnsValidToken", testAuthReturnsValidToken),
        ("testIosApp", testIosApp),
        ("testOldIosApp", testOldIosApp),
        ("testAppUploadsToRightTeamAndCluster", testAppUploadsToRightTeamAndCluster),
        ("testOldIosAppWithInfo", testOldIosAppWithInfo),
        ("testOldIosAppTokenUpload", testOldIosAppTokenUpload),
        ("testPlistForApp", testPlistForApp),
        ("testUnobfuscatedApkUploadWithJWTAuth", testUnobfuscatedApkUploadWithJWTAuth)
    ]
    
    func testLinuxTests() {
        doTestLinuxTestsAreOk()
    }
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        app = Application.testable.newBoostTestApp(configure: { (config, env, services) in
            services.register(RemoteFileCoreServiceMock(), as: CoreManager.self)
            config.prefer(RemoteFileCoreServiceMock.self, for: CoreManager.self)
        })
        
        app.testable.delete(allFor: Token.self)
        
        setupApps()
    }
    
    override func tearDown() {
        deleteAllFiles()
        
        super.tearDown()
    }
    
    // MARK: Tests
    
    func testGetApps() {
        let count = app.testable.count(allFor: Build.self)
        XCTAssertEqual(count, 65, "There should be right amount of apps to begin with")
        
        let req = HTTPRequest.testable.get(uri: "/builds", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: Builds.self)!
        
        XCTAssertEqual(objects.count, 57, "There should be right amount of apps")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testGetAppsOverview() {
        let req = HTTPRequest.testable.get(uri: "/apps", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: [Cluster.Public].self)!
        
        XCTAssertEqual(objects.count, 15, "There should be right amount of apps")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testGetAppsOverviewSortedByNameAsc() {
        let req = HTTPRequest.testable.get(uri: "/apps?sort=name", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: [Cluster.Public].self)!
        
        let sortedObjects = objects.sorted { $0.latestBuildName < $1.latestBuildName }
        
        var x = 0
        for original in objects {
            let sorted = sortedObjects[x]
            XCTAssertEqual(original, sorted, "Result has not been sorted properly")
            x += 1
            if sorted != original {
                break
            }
        }
        
        XCTAssertEqual(objects.count, 15, "There should be right amount of apps")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testAppSearch() {
        let req = HTTPRequest.testable.get(uri: "/apps?search=App%201", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: [Cluster.Public].self)!
        
        XCTAssertEqual(objects.count, 1, "There should be right amount of apps")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testPartialAppSearch() {
        let req = HTTPRequest.testable.get(uri: "/apps?search=ios", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: [Cluster.Public].self)!
        
        XCTAssertEqual(objects.count, 7, "There should be right amount of apps")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testPartialInsensitiveAppSearch() {
        let req = HTTPRequest.testable.get(uri: "/apps?search=iOS", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: [Cluster.Public].self)!
        
        XCTAssertEqual(objects.count, 7, "There should be right amount of apps")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testGetApp() {
        let req = HTTPRequest.testable.get(uri: "/builds/\(app1.id!.uuidString)", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        // By getting the content we make sure we got the right model
        _ = r.response.testable.content(as: Build.Public.self)!
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testDeleteApp() {
        let buildIdentifier = "android-app-on-team-2"
        
        let fakeReq = app.testable.fakeRequest()
        let fc = try! fakeReq.makeFileCore()
        try! fc.save(file: ":)".data(using: .utf8)!, to: app2!.appPath!.relativePath, mime: MediaType(type: "application", subType: "octet-stream"), on: fakeReq).wait()
        
        var originalNumberOfBuildsInCluster = 7
        
        let originalCluster: Cluster = try! Cluster.query(on: fakeReq).filter(\Cluster.identifier == buildIdentifier).first().wait()!
        XCTAssertEqual(originalNumberOfBuildsInCluster, originalCluster.buildCount, "Cluster should have a correct count")
        
        var appsCountForCluster = try! Build.query(on: fakeReq).filter(\Build.identifier == buildIdentifier).count().wait()
        XCTAssertEqual(originalNumberOfBuildsInCluster, appsCountForCluster, "Number of cluster apps should correspond the cluster count")
        
        var numberOfApps = 65
        
        var count = app.testable.count(allFor: Build.self)
        XCTAssertEqual(count, numberOfApps, "There should be right amount of apps to begin with")
        
        count = app.testable.count(allFor: Tag.self)
        XCTAssertEqual(count, 18, "There should be right amount of tags to begin with")
        
        let builds = try! Build.query(on: fakeReq).filter(\Build.identifier == buildIdentifier).all().wait()
        for b in builds {
            let req = HTTPRequest.testable.delete(uri: "/builds/\(b.id!.uuidString)", authorizedUser: user2, on: app)
            let r = app.testable.response(to: req)
            
            r.response.testable.debug()
            
            // TODO: Test only tags shared with nothing else were deleted!!!!
            // TODO: Test all files were deleted!!!!
            
            originalNumberOfBuildsInCluster -= 1
            let originalCluster: Cluster? = try! Cluster.query(on: fakeReq).filter(\Cluster.identifier == buildIdentifier).first().wait()
            XCTAssertEqual(originalNumberOfBuildsInCluster, originalCluster?.buildCount ?? 0, "Cluster should have a correct count")
            
            let buildsCountForCluster = try! Build.query(on: fakeReq).filter(\Build.identifier == buildIdentifier).count().wait()
            XCTAssertEqual(originalNumberOfBuildsInCluster, buildsCountForCluster, "Number of cluster apps should correspond the cluster count")
            
            XCTAssertTrue(r.response.testable.has(statusCode: .noContent), "Wrong status code")
            XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
            
            numberOfApps -= 1
            count = app.testable.count(allFor: Build.self)
            XCTAssertEqual(count, numberOfApps, "There should be right amount of apps to finish with")
        }
        
        count = app.testable.count(allFor: Tag.self)
        XCTAssertEqual(count, 4, "There should be right amount of tags to finish with")
        
        count = try! Cluster.query(on: fakeReq).filter(\Cluster.identifier == buildIdentifier).count().wait()
        XCTAssertEqual(0, count, "Cluster should have been deleted")
        
        appsCountForCluster = try! Build.query(on: fakeReq).filter(\Build.identifier == buildIdentifier).count().wait()
        XCTAssertEqual(appsCountForCluster, 0, "There should be no apps for the cluster")
    }
    
    func testAppTags() {
        let req = HTTPRequest.testable.get(uri: "/builds/\(app1.id!.uuidString)/tags", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: Tags.self)
        
        XCTAssertEqual(objects?.count, 2)
        
        XCTAssertEqual(objects?[0].identifier, "tag-for-app-1")
        XCTAssertEqual(objects?[1].identifier, "tag-for-app-1")
    }
    
    func testCantDeleteOtherPeoplesApp() {
        var count = app.testable.count(allFor: Build.self)
        XCTAssertEqual(count, 65, "There should be right amount of apps to begin with")
        
        let req = HTTPRequest.testable.delete(uri: "/builds/\(app2.id!.uuidString)", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let object = app.testable.one(for: Build.self, id: app2!.id!)
        let tagsCount = try! object!.tags.query(on: r.request).count().wait()
        XCTAssertEqual(tagsCount, 2)
        
        // TODO: Test files are still there!!!
        
        XCTAssertTrue(r.response.testable.has(statusCode: .notFound), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
        
        count = app.testable.count(allFor: Build.self)
        XCTAssertEqual(count, 65, "There should be right amount of apps to finish with")
    }
    
    func testDeleteCluster() {
        let fakeReq = app.testable.fakeRequest()
        
        Build.testable.create(team: team1, name: "App 2", identifier: "app2", version: "3.2.1", build: "654322", platform: .android, on: app)
        Build.testable.create(team: team1, name: "App 2", identifier: "app2", version: "3.2.1", build: "654323", platform: .android, on: app)
        Build.testable.create(team: team1, name: "App 2", identifier: "app2", version: "3.2.1", build: "654324", platform: .android, on: app)
        let clustered = Build.testable.create(team: team1, name: "App 2", identifier: "app2", version: "3.2.2", build: "1", platform: .android, on: app)
        
        var count = app.testable.count(allFor: Build.self)
        XCTAssertEqual(count, 69, "There should be right amount of apps to begin with")
        
        count = app.testable.count(allFor: Cluster.self)
        XCTAssertEqual(count, 17, "There should be right amount of clusters to begin with")
        
        count = app.testable.count(allFor: Tag.self)
        XCTAssertEqual(count, 18, "There should be right amount of tags to begin with")
        
        count = try! Cluster.query(on: fakeReq).filter(\Cluster.id == clustered.clusterId).count().wait()
        XCTAssertEqual(count, 1, "The right cluster should be there")
        
        let req = HTTPRequest.testable.delete(uri: "/apps/\(clustered.clusterId.uuidString)", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        XCTAssertTrue(r.response.testable.has(statusCode: .noContent), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
        
        count = app.testable.count(allFor: Build.self)
        XCTAssertEqual(count, 64, "There should be right amount of apps to finish with")
        
        count = app.testable.count(allFor: Cluster.self)
        XCTAssertEqual(count, 16, "There should be right amount of clusters to finish with")
        
        count = try! Cluster.query(on: fakeReq).filter(\Cluster.id == clustered.clusterId).count().wait()
        XCTAssertEqual(count, 0, "The right cluster should have been deleted")
        
        count = app.testable.count(allFor: Tag.self)
        XCTAssertEqual(count, 16, "There should be right amount of tags to finish with")
    }
    
    func testIosApp() {
        // TODO: Change app!!!!!
        doTestJWTUpload(appFileName: "app2.ipa", platform: .ios, name: "Cocktail", identifier: "Marco-Tini.Cocktail", version: "1.9", build: "1", iconSize: 30056)
    }
    
    func testOldIosApp() {
        doTestJWTUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776)
    }
    
    func testAppUploadsToRightTeamAndCluster() {
        let fakeReq = app.testable.fakeRequest()
        
        _ = try! team2.users.attach(user1, on: fakeReq).wait()
        
        // Get and check first app
        let r1 = doTestJWTUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776, team: team1)
        
        let object1 = r1.response.testable.content(as: Build.self)!
        let cluster1 = Cluster.testable.cluster(withId: object1.clusterId, on: app)
        XCTAssertNotNil(object1.teamId)
        XCTAssertEqual(object1.teamId, team1.id, "Cluster 1 belongs to team 1")
        XCTAssertEqual(cluster1.buildCount, 1, "Cluster has 1 app counted")
        
        // Get and check second app
        let r2 = doTestJWTUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776, team: team2, appsTotal: 66)
        
        let object2 = r2.response.testable.content(as: Build.self)!
        let cluster2 = Cluster.testable.cluster(withId: object2.clusterId, on: app)
        XCTAssertNotNil(object2.teamId)
        XCTAssertEqual(object2.teamId, team2.id, "Cluster 2 belongs to team 2")
        XCTAssertEqual(cluster2.buildCount, 1, "Cluster has 1 app counted")
        
        // Get and check second app
        let r3 = doTestJWTUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776, team: team2, appsTotal: 67)
        
        let object3 = r3.response.testable.content(as: Build.self)!
        let cluster3 = Cluster.testable.cluster(withId: object3.clusterId, on: app)
        XCTAssertNotNil(object3.teamId)
        XCTAssertEqual(object3.teamId, team2.id, "Cluster 2 belongs to team 2")
        XCTAssertEqual(cluster3.buildCount, 2, "Cluster has 2 apps counted")
        
        XCTAssertNotNil(cluster1.id)
        XCTAssertNotEqual(cluster1.id, cluster2.id, "Check clusters are not the same for the first two apps")
        
        XCTAssertNotNil(cluster1.id)
        XCTAssertEqual(cluster2.id, cluster3.id, "Check clusters are the same for the second two apps")
    }
    
    func testOldIosAppWithInfo() {
        // TODO: Build the URL properly
        let jira = "http://jira.example.com/tickets?id=123456".encodeURLforUseAsQuery()
        let jiraMessage = "Build a wall, big wall, we are good at building walls!\nVERY GOOD!".encodeURLforUseAsQuery()
        let pr = "http://github.example.com/pull/6".encodeURLforUseAsQuery()
        let prMessage = "Adding bricks\nAnd mortar".encodeURLforUseAsQuery()
        let commit = "http://github.example.com/commit/ig84rtx1984r9h2837yrx28".encodeURLforUseAsQuery()
        let commitMessage = "Another brick in the wall!".encodeURLforUseAsQuery()
        
        let r = doTestJWTUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776, info: "&pm[ticket][url]=\(jira)&pm[ticket][message]=\(jiraMessage)&sc[commit][url]=\(commit)&sc[commit][message]=\(commitMessage)&sc[pr][url]=\(pr)&sc[pr][message]=\(prMessage)&sc[commit][id]=ig84rtx1984r9h2837yrx28")
        
        let object = r.response.testable.content(as: Build.self)!
        XCTAssertNil(object.info!.projectManagement!.ticket!.id, "We are not sending an Id")
        XCTAssertEqual(object.info!.projectManagement!.ticket!.url, jira.removingPercentEncoding)
        XCTAssertEqual(object.info!.projectManagement!.ticket!.message, jiraMessage.removingPercentEncoding)
        
        XCTAssertNil(object.info!.sourceControl!.pr!.id, "We are not sending an Id so where did this come from!")
        XCTAssertEqual(object.info!.sourceControl!.pr!.url, pr.removingPercentEncoding)
        XCTAssertEqual(object.info!.sourceControl!.pr!.message, prMessage.removingPercentEncoding)
        
        XCTAssertEqual(object.info!.sourceControl!.commit!.id, "ig84rtx1984r9h2837yrx28")
        XCTAssertEqual(object.info!.sourceControl!.commit!.url, commit)
        XCTAssertEqual(object.info!.sourceControl!.commit!.message, commitMessage.removingPercentEncoding)
    }
    
    func testOldIosAppTokenUpload() {
        doTestTokenUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776)
    }
    
    func testAppIconIsRetrieved() {
        // Preps
        let resourcesIconUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("icons").appendingPathComponent("liveui.png")
        
        let fakeReq = app.testable.fakeRequest()
        let postData = try! Data(contentsOf: resourcesIconUrl)
        try! app1.save(iconData: postData, on: fakeReq).wait()
        app1.iconHash = try! postData.asMD5String()
        _ = try! app1.save(on: fakeReq).wait()
        
        // Test
        let req = HTTPRequest.testable.get(uri: "/builds/\(app1.id!.uuidString)/icon", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        XCTAssertTrue(r.response.testable.has(statusCode: .movedPermanently), "Wrong status code")
        XCTAssertEqual(r.response.testable.header(name: "location"), "https://example.com/apps/icons/\(app1.iconHash!).png", "Missing or incorrect content type")
        
        // Cleaning
        try! app1.deleteIcon(on: fakeReq).wait()
    }
    
    func testAppIconIsRetrievedFromLocalStore() {
        let fakeReq = app.testable.fakeRequest()
        let fm = try! fakeReq.makeFileCore() as! RemoteFileCoreServiceMock
        
        // Switch mock to local file store
        fm.isRemote = false
        
        // Preps
        let resourcesIconUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("icons").appendingPathComponent("liveui.png")
        
        let postData: Data = try! Data(contentsOf: resourcesIconUrl)
        
        try! app1.save(iconData: postData, on: fakeReq).wait()
        app1.iconHash = try! postData.asMD5String()
        _ = try! app1.save(on: fakeReq).wait()
        
        // Test
        let req = HTTPRequest.testable.get(uri: "/builds/\(app1.id!.uuidString)/icon", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        XCTAssertEqual(r.response.http.body.data!.count, postData.count, "Icon needs to be the same")
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "image/png"), "Missing or incorrect content type")
        
        // Cleaning
        try! app1.deleteIcon(on: fakeReq).wait()
        fm.isRemote = true
    }
    
    func testBadTokenUpload() {
        let appUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("apps").appendingPathComponent("app.ipa")
        let postData = try! Data(contentsOf: appUrl)
        let req = HTTPRequest.testable.post(uri: "/builds?token=bad_token_yo", data: postData, headers: [
            "Content-Type": "application/octet-stream"
            ]
        )
        
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let object = r.response.testable.content(as: ErrorResponse.self)!
        
        XCTAssertEqual(object.error, "auth_error.authentication_failed", "Wrong code")
        XCTAssertEqual(object.description, "Authentication has failed", "Wrong description")
    }
    
    func testUnobfuscatedApkUploadWithJWTAuth() {
        // TODO: Make another app!!!!!!!!!
        doTestJWTUpload(appFileName: "app.apk", platform: .android, name: "Bytecheck", identifier: "cz.vhrdina.bytecheck", version: "0.1", build: "1", iconSize: 2018)
        // TODO: Test token upload
    }
    
    func testObfuscatedApkUploadWithJWTAuth() {
        doTestJWTUpload(appFileName: "app-obfuscated.apk", platform: .android, name: "BoostTest", identifier: "io.liveui.boosttest", version: "1.0-test", build: "1", iconSize: 9250)
    }
    
    func testAuthReturnsValidToken() {
        let req = HTTPRequest.testable.get(uri: "/builds/\(app1.id!.uuidString)/auth", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let auth = r.response.testable.content(as: DownloadKey.Public.self)!
        
        // PLIST links to a local endpoint
        let plist = "http://localhost:8080/builds/\(app1.id!.uuidString)/plist/\(auth.token)/app.plist"
        
        XCTAssertTrue(!auth.token.isEmpty, "Token can not be empty")
        XCTAssertNotNil(UUID(auth.token), "Token needs to be a valid UUID")
        XCTAssertEqual(UUID(auth.token)?.uuidString.uppercased(), auth.token.uppercased(), "Token needs to be a valid UUID")
        XCTAssertEqual(auth.buildId, app1.id!, "Needs correct build ID")
        // File links to a remote location
        XCTAssertEqual(auth.file, "https://example.com/\(app1.appPath!.relativePath)", "Needs correct file URL")
        XCTAssertEqual(auth.plist, plist, "Needs correct plist URL")
        XCTAssertEqual(auth.userId, user1.id!, "Needs correct user ID")
        XCTAssertEqual(auth.ios, "itms-services://?action=download-manifest&url=\(plist)", "Needs correct iTunes URL")
        
        let fakeReq = app.testable.fakeRequest()
        let dbToken = try! DownloadKey.query(on: fakeReq).filter(\DownloadKey.token == auth.token.sha()).first().wait()!
        try! XCTAssertEqual(auth.token.sha(), dbToken.token, "Token needs to be valid")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testPlistForApp() {
        let realBuild = createRealBuild()
        
        let token = DownloadKey.testable.create(forBuildId: realBuild.id!, user: user1, on: app)
        
        let r = app.testable.response(to: HTTPRequest.testable.get(uri: "/builds/\(realBuild.id!)/plist/\(token.token)/\(realBuild.fileName).plist", authorizedUser: user1, on: app))
        r.response.testable.debug()
        
        let plistData = r.response.testable.contentString!.data(using: .utf8)!
        
        let link = "https://example.com/\(realBuild.appPath!.relativeString)"
        
        // Temporary hack before PropertyListDecoder becomes available on linux (https://bugs.swift.org/browse/SR-8259)
        #if os(Linux)
        let plistString = String(data: plistData, encoding: .utf8)!
        XCTAssertTrue(plistString.contains(link))
        #elseif os(macOS)
        let plist = try! PropertyListDecoder().decode(BuildPlist.self, from: plistData)
        
        XCTAssertEqual(plist.items[0].assets[0].kind, "software-package")
        XCTAssertEqual(plist.items[0].assets[0].url, link)
        
        XCTAssertEqual(plist.items[0].metadata.bundleIdentifier, "com.fuerteint.iDeviant")
        XCTAssertEqual(plist.items[0].metadata.bundleVersion, "4.0")
        XCTAssertEqual(plist.items[0].metadata.kind, "software")
        XCTAssertEqual(plist.items[0].metadata.title, "iDeviant")
        #endif
    }
    
    func testDownloadIosApp() {
        let realBuild = createRealBuild()
        
        let token = DownloadKey.testable.create(forBuildId: realBuild.id!, user: user1, on: app)
        
        let r = app.testable.response(to: HTTPRequest.testable.get(uri: "/builds/\(realBuild.id!)/file/\(token.token)/\(realBuild.fileName).ipa", authorizedUser: user1, on: app))
        r.response.testable.debug()
        
        let fakeReq = app.testable.fakeRequest()
        let fm = try! fakeReq.makeFileCore() as! RemoteFileCoreServiceMock
        
        let path = "apps/\(realBuild.created.year)/\(realBuild.created.month)/\(realBuild.created.day)/\(realBuild.id!)/app.ipa"
        
        XCTAssertEqual(path, fm.movedFiles.first!.destination, "Downloaded app doesn't match the one uploaded")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/octet-stream"), "Missing or incorrect content type")
    }
    
    func testDownloadAndroidApp() {
        let realBuild = createRealBuild(.android)
        
        let token = DownloadKey.testable.create(forBuildId: realBuild.id!, user: user1, on: app)
        
        let r = app.testable.response(to: HTTPRequest.testable.get(uri: "/builds/\(realBuild.id!)/file/\(token.token)/\(realBuild.fileName).apk", authorizedUser: user1, on: app))
        r.response.testable.debug()
        
        let fakeReq = app.testable.fakeRequest()
        let fm = try! fakeReq.makeFileCore() as! RemoteFileCoreServiceMock
        
        let path = "apps/\(realBuild.created.year)/\(realBuild.created.month)/\(realBuild.created.day)/\(realBuild.id!)/app.apk"
        
        XCTAssertEqual(path, fm.movedFiles.first!.destination, "Downloaded app doesn't match the one uploaded")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/vnd.android.package-archive"), "Missing or incorrect content type")
    }
    
}


extension AppsControllerTests {
    
    private func createRealBuild(_ platform: Build.Platform = .ios) -> Build {
        if platform == .ios {
            let r = doTestTokenUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776)
            let app = r.response.testable.content(as: Build.self)!
            return app
        } else {
            let r = doTestJWTUpload(appFileName: "app.apk", platform: .android, name: "Bytecheck", identifier: "cz.vhrdina.bytecheck", version: "0.1", build: "1", iconSize: 2018)
            let app = r.response.testable.content(as: Build.self)!
            return app
        }
    }
    
    @discardableResult private func doTestTokenUpload(appFileName fileName: String, platform: Build.Platform, name: String, identifier: String, version: String? = nil, build: String? = nil, tags: [String] = ["tagging_like_crazy", "All Year Round"], iconSize: Int? = nil) -> TestResponse {
        let buildUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("apps").appendingPathComponent(fileName)
        let postData = try! Data(contentsOf: buildUrl)
        let encodedTags: String = tags.joined(separator: "|").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let req = HTTPRequest.testable.post(uri: "/builds?tags=\(encodedTags)&token=\(key1.token)", data: postData, headers: [
            "Content-Type": (platform == .ios ? "application/octet-stream" : "application/vnd.android.package-archive")
            ]
        )
        
        return doTest(request: req, platform: platform, name: name, identifier: identifier, version: version, build: build, tags: tags, iconSize: iconSize)
    }
    
    @discardableResult private func doTestJWTUpload(appFileName fileName: String, platform: Build.Platform, name: String, identifier: String, version: String? = nil, build: String? = nil, tags: [String] = ["tagging_like_crazy", "All Year Round"], iconSize: Int? = nil, info: String? = nil, team: Team? = nil, appsTotal: Int = 65) -> TestResponse {
        let buildUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("apps").appendingPathComponent(fileName)
        let postData = try! Data(contentsOf: buildUrl)
        let encodedTags: String = tags.joined(separator: "|").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let safeInfo = (info ?? "")
        let uri = "/teams/\((team ?? team1).id!.uuidString)/builds?tags=\(encodedTags)\(safeInfo)"
        let req = HTTPRequest.testable.post(uri: uri, data: postData, headers: [
            "Content-Type": (platform == .ios ? "application/octet-stream" : "application/vnd.android.package-archive")
            ], authorizedUser: user1, on: app
        )
        
        return doTest(request: req, platform: platform, name: name, identifier: identifier, version: version, build: build, tags: tags, iconSize: iconSize, appsTotal: appsTotal)
    }
    
    @discardableResult private func doTest(request req: HTTPRequest, platform: Build.Platform, name: String, identifier: String, version: String?, build: String?, tags: [String], iconSize: Int?, appsTotal: Int = 65) -> TestResponse {
        // Check initial app count
        var count = app.testable.count(allFor: Build.self)
        XCTAssertEqual(count, appsTotal, "There should be right amount of apps to begin with")
        
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let object = r.response.testable.content(as: Build.self)!
        
        // TODO: Test email notification has been received!!!!!!!!
        let mailer = try! r.request.make(MailerService.self) as! MailerMock
        XCTAssertTrue(ApiCoreBase.configuration.mail.email.count > 0, "Sender should not be empty")
        XCTAssertEqual(mailer.receivedMessage!.from, ApiCoreBase.configuration.mail.email, "Email has a wrong sender")
        XCTAssertEqual(mailer.receivedMessage!.to, "admin@apicore", "Email has a wrong recipient")
        XCTAssertEqual(mailer.receivedMessage!.subject, "Install \(name) - \(ApiCoreBase.configuration.server.name)", "Email has a wrong subject")
        
        XCTAssertTrue(mailer.receivedMessage!.text.count > 50, "Text template should be present")
        XCTAssertTrue(mailer.receivedMessage!.html!.count > 50, "Text template should be present")
        
        // Check parsed values
        XCTAssertEqual(object.platform, platform, "Wrong platform")
        XCTAssertEqual(object.name, name, "Wrong name")
        XCTAssertEqual(object.identifier, identifier, "Wrong identifier")
        XCTAssertEqual(object.version, version ?? "0.0", "Wrong version")
        XCTAssertEqual(object.build, build ?? "0", "Wrong build")
        
        let fakeReq = app.testable.fakeRequest()
        let fm = try! fakeReq.makeFileCore() as! RemoteFileCoreServiceMock
        
        // Temp file should have been deleted
        let pathUrl = Build.localTempAppFile(on: r.request)
        XCTAssertFalse(FileManager.default.fileExists(atPath: pathUrl.path), "Temporary file should have been deleted")
        
        // App should be saved in the persistent storage
        let path = "apps/\(object.created.year)/\(object.created.month)/\(object.created.day)/\(object.id!)/app.\(platform.fileExtension)"
        XCTAssertTrue(fm.movedFiles.contains(where: { $0.destination == path }), "Persistent file should be present")
        
        // Test images are all okey
        if let iconSize = iconSize, let iconPath = object.iconPath {
            let savedFile = fm.savedFiles.icon(hash: object.iconHash!)
            
            XCTAssertEqual(savedFile!.path, iconPath.relativePath, "Icon file should at the right location")
            XCTAssertEqual(savedFile!.file!.count, iconSize, "Icon file size doesn't match")
        }
        else if object.hasIcon {
            XCTFail("Icon is set on the App object but it has not been tested")
        }
        
        // TODO: Test iOS images are decoded!!!!!!!!!
        
        // Check all created tags
        let allTags = try! object.tags.query(on: fakeReq).all().wait()
        for tag in tags {
            XCTAssertTrue(allTags.contains(identifier: tag.safeText), "Tags need to be present")
        }
        
        // Check final app count after the upload
        count = app.testable.count(allFor: Build.self)
        XCTAssertEqual(count, (appsTotal + 1), "There should be right amount of apps to begin with")
        
        return r
    }
    
}
