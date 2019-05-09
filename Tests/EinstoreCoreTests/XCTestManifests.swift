import XCTest

extension ApiKeysControllerTests {
    static let __allTests = [
        ("testChangeApiKeyName", testChangeApiKeyName),
        ("testCreateApiKey", testCreateApiKey),
        ("testDeleteApiKey", testDeleteApiKey),
        ("testGetApiKeysForTeam", testGetApiKeysForTeam),
        ("testGetApiKeysForUser", testGetApiKeysForUser),
        ("testGetOneApiKey", testGetOneApiKey),
        ("testLinuxTests", testLinuxTests),
    ]
}

extension AppsControllerTests {
    static let __allTests = [
        ("testAppIconIsRetrieved", testAppIconIsRetrieved),
        ("testAppSearch", testAppSearch),
        ("testAppTags", testAppTags),
        ("testAppUploadsToRightTeamAndCluster", testAppUploadsToRightTeamAndCluster),
        ("testAuthReturnsValidToken", testAuthReturnsValidToken),
        ("testBadTokenUpload", testBadTokenUpload),
        ("testCantDeleteOtherPeoplesApp", testCantDeleteOtherPeoplesApp),
        ("testDeleteApp", testDeleteApp),
        ("testDeleteCluster", testDeleteCluster),
        ("testDownloadAndroidApp", testDownloadAndroidApp),
        ("testDownloadIosApp", testDownloadIosApp),
        ("testGetApp", testGetApp),
        ("testGetApps", testGetApps),
        ("testGetAppsOverview", testGetAppsOverview),
        ("testGetAppsOverviewSortedByNameAsc", testGetAppsOverviewSortedByNameAsc),
        ("testIosApp", testIosApp),
        ("testLinuxTests", testLinuxTests),
        ("testObfuscatedApkUploadWithJWTAuth", testObfuscatedApkUploadWithJWTAuth),
        ("testOldIosApp", testOldIosApp),
        ("testOldIosAppTokenUpload", testOldIosAppTokenUpload),
        ("testOldIosAppWithInfo", testOldIosAppWithInfo),
        ("testPartialAppSearch", testPartialAppSearch),
        ("testPartialInsensitiveAppSearch", testPartialInsensitiveAppSearch),
        ("testPlistForApp", testPlistForApp),
        ("testUnobfuscatedApkUploadWithJWTAuth", testUnobfuscatedApkUploadWithJWTAuth),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ApiKeysControllerTests.__allTests),
        testCase(AppsControllerTests.__allTests),
    ]
}
#endif
