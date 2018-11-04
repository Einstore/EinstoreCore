//
//  Apk.swift
//  App
//
//  Created by Ondrej Rafaj on 09/12/2017.
//

import Foundation
import Vapor
import ApiCore
import SwiftShell
import ErrorsCore


/// APK Extractor
class Apk: BaseExtractor, Extractor {
    
    /// Error
    enum Error: FrontendError {
        
        /// Missing manifest file
        case missingManifestFile
        
        /// Error code
        var identifier: String {
            return "extractor.apk.missing_mainifest_file"
        }
        
        /// Reason to fail
        var reason: String {
            return "Missing manifest file"
        }
        
        /// Error HTTP status code
        var status: HTTPStatus {
            return .preconditionFailed
        }
        
    }
    
    func fetchApkInfo() -> ApkInfo {
        var apkInfo: ApkInfo = ApkInfo()
        let output = run(ThirdpartyUtilities.aaptUrl.path.replacingOccurrences(of: "file://", with: ""), "dump", "--values", "badging", self.file.path).stdout
        let outputLines = output.lines()
        outputLines.forEach() {
            if $0.contains(":") {
                let line = $0.split(separator: ":")
                let key = String(line[0])
                let value = String(line[1])
                
                if key == ApkInfo.ParseKeys.package.rawValue {
                    apkInfo.addPackageInfo(package: value)
                } else if key == ApkInfo.ParseKeys.sdkVersion.rawValue {
                    apkInfo.sdkVersion = value
                } else if key == ApkInfo.ParseKeys.targetSdkVersion.rawValue {
                    apkInfo.targetSdkVersion = value
                } else if ApkInfo.ParseKeys.hasPermission(perm: key) {
                    apkInfo.addPermission(permission: value)
                } else if ApkInfo.ParseKeys.hasFeature(feature: key) {
                    apkInfo.addFeature(feature: value)
                } else if ApkInfo.ParseKeys.isLabel(key: key) {
                    apkInfo.addApplicationLabel(key: key, label: value)
                } else if key == ApkInfo.ParseKeys.application.rawValue {
                    apkInfo.addApplicationInfo(rawData: value)
                } else if key == ApkInfo.ParseKeys.supportsScreens.rawValue {
                    apkInfo.addSupportsScreens(rawData: value)
                } else if key == ApkInfo.ParseKeys.locales.rawValue {
                    apkInfo.addLocales(rawData: value)
                } else if key == ApkInfo.ParseKeys.nativeCode.rawValue {
                    apkInfo.addNativeCode(rawData: value)
                } else if ApkInfo.ParseKeys.isDensityIcon(key: key) {
                    apkInfo.addApplicationIconForDensity(key: key, icon: value)
                }
            }
        }
        
        return apkInfo
    }
    
    //TODO fix grep cmd
    func findAppIconPath(iconName: String?) -> [String]? {
        guard let iconName = iconName else {
            return nil
        }
        
        let output = run(ThirdpartyUtilities.aaptUrl.path.replacingOccurrences(of: "file://", with: ""),
                         "dump",
                         "--values",
                         "resources",
                         self.file.path,
                         "|",
                         "grep",
                         "-w",
                         "'"+iconName+"'").stdout
        
        let patternPath = "\".+\""
        let patternName = "/"+iconName+"\\."

        let outputLines = output.lines().filter {
            let string = $0 as NSString
            let regexPath = try? NSRegularExpression(pattern: patternPath, options: .caseInsensitive)
            let regexName = try? NSRegularExpression(pattern: patternName, options: .caseInsensitive)
            let range = NSRange(location: 0, length: string.length)
            return string.contains(iconName) && regexPath?.firstMatch(in: $0, options: [], range: range) != nil && regexName?.firstMatch(in: $0, options: [], range: range) != nil
        }
        
        return outputLines.map {
            let string = $0 as NSString
            let regexValue = try? NSRegularExpression(pattern: patternPath, options: .caseInsensitive)
            let range = NSRange(location: 0, length: string.length)
            let path = regexValue?.firstMatch(in: $0, options: [], range: range).map {
                string.substring(with: $0.range).replacingOccurrences(of: "\"", with: "")
            }
            return path ?? ""
        }
    }
    
    /// Process app
    func process(teamId: DbIdentifier, on req: Request) throws -> Future<App> {
        let promise = request.eventLoop.newPromise(App.self)
        
        DispatchQueue.global().async {
            do {
                
                var apk = self.fetchApkInfo()
                self.appName = apk.applicationLabel
                self.appIdentifier = apk.packageName
                self.versionLong = apk.versionName
                self.versionShort = apk.versionCode
                self.minSdk = apk.sdkVersion
                apk.setIconPath(path: self.findAppIconPath(iconName: apk.getIconName()))
                
                // TODO: Make the following unblocking!!!
                let a = try self.app(platform: .android, teamId: teamId, on: req).wait()
                promise.succeed(result: a)
            } catch {
                promise.fail(error: error)
            }
        }
        
        return promise.futureResult
    }
    
}
