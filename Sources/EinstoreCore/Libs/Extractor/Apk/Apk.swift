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
    
    var extractedApkFolder: URL {
        get {
            return archive
        }
    }
    
    func fetchApkInfo() -> ApkInfo {
        var apkInfo: ApkInfo = ApkInfo()
        #if os(macOS)
        let aapt = ThirdpartyUtilities.aaptUrl.path.replacingOccurrences(of: "file://", with: "")
        #elseif os(Linux)
        let aapt = "/usr/bin/aapt"
        #endif
        
        // Following code will be only used if gradle date stamp is enabled
        func setBuiltFromZip() {
            let archivedLines = run("/usr/bin/unzip", "-l", file.path).stdout.lines()
            
            var manifestInfo: [String] = []
            for line in archivedLines {
                if line.contains("AndroidManifest.xml") {
                    manifestInfo = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).condenseWhitespace().split(separator: " ").map({ String($0) })
                    break
                }
            }
            
            if manifestInfo.count >= 4 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "mm-dd-yyyy HH:mm"
                if let date = dateFormatter.date(from: ("\(manifestInfo[1]) \(manifestInfo[2])")) {
                    built = date
                }
            }
        }
        setBuiltFromZip()
        
        if built == nil {
            built = Date()
        }
        
        let output = run(aapt, "dump", "--values", "badging", file.path).stdout
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
    
    // TODO: fix grep cmd
    func findAppIconPath(iconName: String?) -> [String]? {
        guard let iconName = iconName else {
            return nil
        }
        
        #if os(macOS)
        let aapt = ThirdpartyUtilities.aaptUrl.path.replacingOccurrences(of: "file://", with: "")
        #elseif os(Linux)
        let aapt = "/usr/bin/aapt"
        #endif
        let output = run(aapt,
                         "dump",
                         "--values",
                         "resources",
                         self.file.path,
                         "|",
                         "grep",
                         "-w",
                         "\"\(iconName)\"").stdout
        
        let patternPath = "\".+\""
        let patternName = "/\(iconName)\\."
        
        let outputLines = output.lines().filter {
            let string = $0 as NSString
            let regexPath = try? NSRegularExpression(pattern: patternPath, options: .caseInsensitive)
            let regexName = try? NSRegularExpression(pattern: patternName, options: .caseInsensitive)
            let range = NSRange(location: 0, length: string.length)
            return string.contains(iconName)
                && !string.contains(".xml")
                && regexPath?.firstMatch(in: $0, options: [], range: range) != nil
                && regexName?.firstMatch(in: $0, options: [], range: range) != nil
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
    
    func getApplicationIcon(path: String?) throws {
        guard let iconPath = path else {
            return
        }
        
        #if os(macOS)
        let unzip = "unzip"
        #elseif os(Linux)
        let unzip = "/usr/bin/unzip"
        #endif
        try runAndPrint(unzip, "-o", self.file.path, iconPath, "-d", self.archive.path)
        var pathUrl: URL = extractedApkFolder
        pathUrl.appendPathComponent(iconPath)
        if FileManager.default.fileExists(atPath: pathUrl.path) {
            let data: Data = try Data(contentsOf: pathUrl)
            if data.count > (iconData?.count ?? 0) {
                iconData = data
            }
        }
    }
    
    /// Process app
    func process(teamId: DbIdentifier, on req: Request) throws -> Future<Build> {
        let promise = request.eventLoop.newPromise(Build.self)
        DispatchQueue.global().async {
            do {
                var apk = self.fetchApkInfo()
                self.appName = apk.applicationLabel
                self.appIdentifier = apk.packageName
                self.versionLong = apk.versionName
                self.versionShort = apk.versionCode
                self.minSdk = apk.sdkVersion
                apk.setIconPath(path: self.findAppIconPath(iconName: apk.getIconName()))
                try self.getApplicationIcon(path: apk.getIconPath())
                
                try self.app(platform: .android, teamId: teamId, on: req).do({ build in
                    promise.succeed(result: build)
                }).catch({ error in
                    promise.fail(error: error)
                })
            } catch {
                promise.fail(error: error)
            }
        }
        
        return promise.futureResult
    }
    
}
