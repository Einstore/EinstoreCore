//
//  AppsControllerTests.swift
//  BoostCoreTests
//
//  Created by Ondrej Rafaj on 05/03/2018.
//

import Foundation
import XCTest
@testable import Vapor
@testable import NIO
import VaporTestTools
import FluentTestTools
import ApiCoreTestTools
import BoostCoreTestTools
import ErrorsCore
@testable import ApiCore
@testable import BoostCore
import PostgreSQL
import FluentPostgreSQL


class AppsControllerTests: XCTestCase, AppTestCaseSetup, LinuxTests {
    
    var app: Application!
    
    var user1: User!
    var user2: User!
    
    var adminTeam: Team!
    var team1: Team!
    var team2: Team!
    
    var key1: UploadKey!
    var key2: UploadKey!
    var key3: UploadKey!
    var key4: UploadKey!
    
    var team4: Team!
    
    var app1: App!
    var app2: App!
    
    
    // MARK: Linux
    
    static let allTests: [(String, Any)] = [
        ("testG etAppsOverview", testGetAppsOverview),
        ("testAppIconIsRetrieved", testAppIconIsRetrieved),
        ("testAppTags", testAppTags),
        ("testAuthReturnsValidToken", testAuthReturnsValidToken),
        ("testBadTokenUpload", testBadTokenUpload),
        ("testCantDeleteOtherPeoplesApp", testCantDeleteOtherPeoplesApp),
        ("testDeleteApp", testDeleteApp),
        ("testDownloadAndroidApp", testDownloadAndroidApp),
        ("testDownloadIosApp", testDownloadIosApp),
        ("testGetApp", testGetApp),
        ("testGetApps", testGetApps),
        ("testLinuxTests", testLinuxTests),
        ("testObfuscatedApkUploadWithJWTAuth", testObfuscatedApkUploadWithJWTAuth),
        ("testIosApp", testIosApp),
        ("testOldIosApp", testOldIosApp),
        ("testAppUploadsToRightTeamAndCluster", testAppUploadsToRightTeamAndCluster),
        ("testOldIosAppWithInfo", testOldIosAppWithInfo),
        ("testOldIosAppTokenUpload", testOldIosAppTokenUpload),
        ("testPlistForApp", testPlistForApp),
        ("testUnobfuscatedApkUploadWithJWTAuth", testUnobfuscatedApkUploadWithJWTAuth),
        ]
    
    func testLinuxTests() {
        doTestLinuxTestsAreOk()
    }
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        app = Application.testable.newBoostTestApp()
        
        app.testable.delete(allFor: Token.self)
        
        setupApps()
    }
    
    override func tearDown() {
        deleteAllFiles()
        
        super.tearDown()
    }
    
    // MARK: Tests
    
    func testGetApps() {
        let count = app.testable.count(allFor: App.self)
        XCTAssertEqual(count, 107, "There should be right amount of apps to begin with")
        
        let req = HTTPRequest.testable.get(uri: "/apps", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: Apps.self)!
        
        XCTAssertEqual(objects.count, 99, "There should be right amount of apps")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testGetAppsOverview() {
        let req = HTTPRequest.testable.get(uri: "/apps/overview", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let objects = r.response.testable.content(as: [Cluster.Public].self)!
        
        XCTAssertEqual(objects.count, 8, "There should be right amount of apps")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testGetApp() {
        let req = HTTPRequest.testable.get(uri: "/apps/\(app1.id!.uuidString)", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        // By getting the content we make sure we got the right model
        _ = r.response.testable.content(as: App.Public.self)!
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
    }
    
    func testDeleteApp() {
        let fakeReq = app.testable.fakeRequest()
        let fc = try! fakeReq.makeFileCore()
        try! fc.save(file: ":)".data(using: .utf8)!, to: app1!.appPath!.relativePath, mime: MediaType(type: "application", subType: "octet-stream"), on: fakeReq).wait()
        
        var count = app.testable.count(allFor: App.self)
        XCTAssertEqual(count, 107, "There should be right amount of apps to begin with")
        
        let req = HTTPRequest.testable.delete(uri: "/apps/\(app1.id!.uuidString)", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)

        r.response.testable.debug()

        // TODO: Test all tags were deleted!!!!
        // TODO: Test only tags shared with nothing else were deleted!!!!
        // TODO: Test all files were deleted!!!!

        XCTAssertTrue(r.response.testable.has(statusCode: .noContent), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")

        count = app.testable.count(allFor: App.self)
        XCTAssertEqual(count, 106, "There should be right amount of apps to finish with")
    }
    
    func testAppTags() {
        let req = HTTPRequest.testable.get(uri: "/apps/\(app1.id!.uuidString)/tags", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
    }
    
    func testCantDeleteOtherPeoplesApp() {
        var count = app.testable.count(allFor: App.self)
        XCTAssertEqual(count, 107, "There should be right amount of apps to begin with")
        
        let req = HTTPRequest.testable.delete(uri: "/apps/\(app2.id!.uuidString)", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let object = app.testable.one(for: App.self, id: app2!.id!)
        let tagsCount = try! object!.tags.query(on: r.request).count().wait()
        XCTAssertEqual(tagsCount, 2)
        
        // TODO: Test files are still there!!!
        
        XCTAssertTrue(r.response.testable.has(statusCode: .notFound), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/json; charset=utf-8"), "Missing or invalid content type")
        
        count = app.testable.count(allFor: App.self)
        XCTAssertEqual(count, 107, "There should be right amount of apps to finish with")
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
        
        // Upload two apps
        let r1 = doTestJWTUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776, team: team1)
        let r2 = doTestJWTUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776, team: team2, appsTotal: 108)
        
        // Get and check first app
        let object1 = r1.response.testable.content(as: App.self)!
        let cluster1 = Cluster.testable.cluster(withId: object1.clusterId, on: app)
        XCTAssertNotNil(object1.teamId)
        XCTAssertEqual(object1.teamId, team1.id)
        
        // Get and check second app
        let object2 = r2.response.testable.content(as: App.self)!
        let cluster2 = Cluster.testable.cluster(withId: object2.clusterId, on: app)
        XCTAssertNotNil(object2.teamId)
        XCTAssertEqual(object2.teamId, team2.id)
        
        // Check clusters are not the same
        XCTAssertNotNil(cluster1.id)
        XCTAssertNotEqual(cluster1.id, cluster2.id)
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
        
        let object = r.response.testable.content(as: App.self)!
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
        let fc = try! fakeReq.makeFileCore()
        let postData = try! Data(contentsOf: resourcesIconUrl)
        try! fc.save(file: postData, to: app1!.iconPath!.relativePath, mime: MediaType.png, on: fakeReq).wait()
        
        // Test
        let req = HTTPRequest.testable.get(uri: "/apps/\(app1.id!.uuidString)/icon", authorizedUser: user1, on: app)
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        XCTAssertEqual(r.response.http.body.data!.count, postData.count, "Icon needs to be the same")
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "image/png"), "Missing or incorrect content type")
        
        // Cleaning
        try! fc.delete(file: app1!.iconPath!.relativePath, on: fakeReq).wait()
    }
    
    func testBadTokenUpload() {
        let appUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("apps").appendingPathComponent("app.ipa")
        let postData = try! Data(contentsOf: appUrl)
        let req = HTTPRequest.testable.post(uri: "/apps?token=bad_token_yo", data: postData, headers: [
            "Content-Type": "application/octet-stream"
            ]
        )
        
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let object = r.response.testable.content(as: ErrorResponse.self)!
        
        XCTAssertEqual(object.error, "auth_error.authentication_failed", "Wrong code")
        XCTAssertEqual(object.description, "Authentication has failed", "Wrong desctiption")
    }
    
    func testUnobfuscatedApkUploadWithJWTAuth() {
        // TODO: Make another app!!!!!!!!!
        doTestJWTUpload(appFileName: "app.apk", platform: .android, name: "Bytecheck", identifier: "cz.vhrdina.bytecheck.ByteCheckApplication", version: "7.1.1", build: "25", iconSize: 2018)
        // TODO: Test token upload
    }
    
    func testObfuscatedApkUploadWithJWTAuth() {
        doTestJWTUpload(appFileName: "app-obfuscated.apk", platform: .android, name: "BoostTest", identifier: "io.liveui.boosttest", iconSize: 9250)
    }
    
    func testAuthReturnsValidToken() {
        // TODO: Finish!!!!!!!!!!!!
    }
    
    func testPlistForApp() {
        let realApp = createRealApp()
        
        let token = DownloadKey.testable.create(forAppId: realApp.id!, user: user1, on: app)
        
        let r = app.testable.response(to: HTTPRequest.testable.get(uri: "/apps/\(realApp.id!)/plist/\(token.token)/\(realApp.fileName).plist", authorizedUser: user1, on: app))
        r.response.testable.debug()
        
        let plistData = r.response.testable.contentString!.data(using: .utf8)!
        
        let link = "http://localhost:8080/apps/\(realApp.id!)/file/\(token.token)/app-ipa.ipa"
        
        // Temporary hack before PropertyListDecoder becomes available on linux (https://bugs.swift.org/browse/SR-8259)
        #if os(Linux)
        let plistString = String(data: plistData, encoding: .utf8)!
        XCTAssertTrue(plistString.contains(link))
        #elseif os(macOS)
        let plist = try! PropertyListDecoder().decode(AppPlist.self, from: plistData)
        
        print(plist)
        
        XCTAssertEqual(plist.items[0].assets[0].kind, "software-package")
        XCTAssertEqual(plist.items[0].assets[0].url, link)
        
        XCTAssertEqual(plist.items[0].metadata.bundleIdentifier, "com.fuerteint.iDeviant")
        XCTAssertEqual(plist.items[0].metadata.bundleVersion, "4.0")
        XCTAssertEqual(plist.items[0].metadata.kind, "software")
        XCTAssertEqual(plist.items[0].metadata.title, "iDeviant")
        #endif
    }
    
    func testDownloadIosApp() {
        let realApp = createRealApp()
        
        let token = DownloadKey.testable.create(forAppId: realApp.id!, user: user1, on: app)
        
        let r = app.testable.response(to: HTTPRequest.testable.get(uri: "/apps/\(realApp.id!)/file/\(token.token)/\(realApp.fileName).ipa", authorizedUser: user1, on: app))
        r.response.testable.debug()
        
        let data: Data = try! r.response.http.body.consumeData(on: app.testable.fakeRequest()).wait()
        
        let appUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("apps").appendingPathComponent("app.ipa")
        let appData = try! Data(contentsOf: appUrl)
        
        XCTAssertEqual(data, appData, "Downloaded app doesn't match the one uploaded")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/octet-stream"), "Missing or incorrect content type")
    }
    
    func testDownloadAndroidApp() {
        let realApp = createRealApp(.android)
        
        let token = DownloadKey.testable.create(forAppId: realApp.id!, user: user1, on: app)
        
        let r = app.testable.response(to: HTTPRequest.testable.get(uri: "/apps/\(realApp.id!)/file/\(token.token)/\(realApp.fileName).apk", authorizedUser: user1, on: app))
        r.response.testable.debug()
        
        let data: Data = try! r.response.http.body.consumeData(on: app.testable.fakeRequest()).wait()
        
        let appUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("apps").appendingPathComponent("app.apk")
        let appData = try! Data(contentsOf: appUrl)
        
        XCTAssertEqual(data, appData, "Downloaded app doesn't match the one uploaded")
        
        XCTAssertTrue(r.response.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(r.response.testable.has(contentType: "application/vnd.android.package-archive"), "Missing or incorrect content type")
    }
    
}


extension AppsControllerTests {
    
    private func createRealApp(_ platform: App.Platform = .ios) -> App {
        if platform == .ios {
            let r = doTestTokenUpload(appFileName: "app.ipa", platform: .ios, name: "iDeviant", identifier: "com.fuerteint.iDeviant", version: "4.0", build: "1.0", iconSize: 4776)
            let app = r.response.testable.content(as: App.self)!
            return app
        } else {
            let r = doTestJWTUpload(appFileName: "app.apk", platform: .android, name: "Bytecheck", identifier: "cz.vhrdina.bytecheck.ByteCheckApplication", version: "7.1.1", build: "25", iconSize: 2018)
            let app = r.response.testable.content(as: App.self)!
            return app
        }
    }
    
    @discardableResult private func doTestTokenUpload(appFileName fileName: String, platform: App.Platform, name: String, identifier: String, version: String? = nil, build: String? = nil, tags: [String] = ["tagging_like_crazy", "All Year Round"], iconSize: Int? = nil) -> TestResponse {
        let appUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("apps").appendingPathComponent(fileName)
        let postData = try! Data(contentsOf: appUrl)
        let encodedTags: String = tags.joined(separator: "|").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let req = HTTPRequest.testable.post(uri: "/apps?tags=\(encodedTags)&token=\(key1.token)", data: postData, headers: [
            "Content-Type": (platform == .ios ? "application/octet-stream" : "application/vnd.android.package-archive")
            ]
        )
        
        return doTest(request: req, platform: platform, name: name, identifier: identifier, version: version, build: build, tags: tags, iconSize: iconSize)
    }
    
    @discardableResult private func doTestJWTUpload(appFileName fileName: String, platform: App.Platform, name: String, identifier: String, version: String? = nil, build: String? = nil, tags: [String] = ["tagging_like_crazy", "All Year Round"], iconSize: Int? = nil, info: String? = nil, team: Team? = nil, appsTotal: Int = 107) -> TestResponse {
        let appUrl = Application.testable.paths.resourcesUrl.appendingPathComponent("apps").appendingPathComponent(fileName)
        let postData = try! Data(contentsOf: appUrl)
        let encodedTags: String = tags.joined(separator: "|").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let safeInfo = (info ?? "")
        let uri = "/teams/\((team ?? team1).id!.uuidString)/apps?tags=\(encodedTags)\(safeInfo)"
        let req = HTTPRequest.testable.post(uri: uri, data: postData, headers: [
            "Content-Type": (platform == .ios ? "application/octet-stream" : "application/vnd.android.package-archive")
            ], authorizedUser: user1, on: app
        )
        
        return doTest(request: req, platform: platform, name: name, identifier: identifier, version: version, build: build, tags: tags, iconSize: iconSize, appsTotal: appsTotal)
    }
    
    @discardableResult private func doTest(request req: HTTPRequest, platform: App.Platform, name: String, identifier: String, version: String?, build: String?, tags: [String], iconSize: Int?, appsTotal: Int = 107) -> TestResponse {
        // Check initial app count
        var count = app.testable.count(allFor: App.self)
        XCTAssertEqual(count, appsTotal, "There should be right amount of apps to begin with")
        
        let r = app.testable.response(to: req)
        
        r.response.testable.debug()
        
        let object = r.response.testable.content(as: App.self)!
        
        // Check parsed values
        XCTAssertEqual(object.platform, platform, "Wrong platform")
        XCTAssertEqual(object.name, name, "Wrong name")
        XCTAssertEqual(object.identifier, identifier, "Wrong identifier")
        XCTAssertEqual(object.version, version ?? "0.0", "Wrong version")
        XCTAssertEqual(object.build, build ?? "0", "Wrong build")
        
        // Temp file should have been deleted
        var pathUrl = App.localTempAppFile(on: r.request)
        XCTAssertFalse(FileManager.default.fileExists(atPath: pathUrl.path), "Temporary file should have been deleted")
        
        // App should be saved in the persistent storage
        pathUrl = object.appPath!
        let appFullPath = URL(fileURLWithPath: ApiCoreBase.configuration.storage.local.root)
            .appendingPathComponent(pathUrl.relativePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: appFullPath.path), "Persistent file should be present")
        
        // Test images are all oke
        if let iconSize = iconSize, let iconPath = object.iconPath {
            let iconFullPath = URL(fileURLWithPath: ApiCoreBase.configuration.storage.local.root)
                .appendingPathComponent(iconPath.relativePath)
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: iconFullPath.path), "Icon file should be present")
            XCTAssertEqual(try? Data(contentsOf: iconFullPath).count, iconSize, "Icon file size doesn't match")
        }
        else if object.hasIcon {
            XCTFail("Icon is set on the App object but it has not been tested")
        }
        
        // TODO: Test iOS images are decoded!!!!!!!!!
        
        // Check all created tags
        let fakeReq = app.testable.fakeRequest()
        let allTags = try! object.tags.query(on: fakeReq).all().wait()
        for tag in tags {
            XCTAssertTrue(allTags.contains(identifier: tag.safeText), "Tags need to be present")
        }
        
        // Check final app count after the upload
        count = app.testable.count(allFor: App.self)
        XCTAssertEqual(count, (appsTotal + 1), "There should be right amount of apps to begin with")
        
        return r
    }
    
}
