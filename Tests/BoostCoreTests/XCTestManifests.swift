import XCTest

extension AppsControllerTests {
    static let __allTests = [
        ("testAppIconIsRetrieved", testAppIconIsRetrieved),
        ("testAppTags", testAppTags),
        ("testBadTokenUpload", testBadTokenUpload),
        ("testCantDeleteOtherPeoplesApp", testCantDeleteOtherPeoplesApp),
        ("testDeleteApp", testDeleteApp),
        ("testGetApp", testGetApp),
        ("testGetAppsOverview", testGetAppsOverview),
        ("testLinuxTests", testLinuxTests),
        ("testObfuscatedApkUploadWithJWTAuth", testObfuscatedApkUploadWithJWTAuth),
        ("testOldIosApp", testOldIosApp),
        ("testOldIosAppTokenUpload", testOldIosAppTokenUpload),
        ("testUnobfuscatedApkUploadWithJWTAuth", testUnobfuscatedApkUploadWithJWTAuth),
    ]
}

extension UploadKeysControllerTests {
    static let __allTests = [
        ("testChangeUploadKeyName", testChangeUploadKeyName),
        ("testCreateUploadKey", testCreateUploadKey),
        ("testDeleteUploadKey", testDeleteUploadKey),
        ("testGetOneUploadKey", testGetOneUploadKey),
        ("testGetUploadKeysForTeam", testGetUploadKeysForTeam),
        ("testGetUploadKeysForUser", testGetUploadKeysForUser),
        ("testLinuxTests", testLinuxTests),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AppsControllerTests.__allTests),
        testCase(UploadKeysControllerTests.__allTests),
    ]
}
#endif
