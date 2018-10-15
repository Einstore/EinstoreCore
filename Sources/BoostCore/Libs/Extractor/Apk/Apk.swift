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
    
    /// Manifest store
    private(set) var manifest: ApkManifest?
    
    /// App permissions store
    private(set) var appPermissions: [String] = []
    
    /// App features store
    private(set) var appFeatures: [String] = []
    
    // MARK: URL's
    
    /// Manifest file URL
    var manifestFileUrl: URL {
        get {
            var manifestFileUrl: URL = extractedApkFolder
            manifestFileUrl.appendPathComponent("AndroidManifest.xml")
            return manifestFileUrl
        }
    }
    
    /// Folder with extracted APK data
    var extractedApkFolder: URL {
        get {
            var url: URL = archive
            url.appendPathComponent("Decoded")
            return url
        }
    }
    
    // MARK: Parsing
    
    /// Parse application name
    private func getApplicationName() throws {
        var pathUrl: URL = extractedApkFolder
        pathUrl.appendPathComponent("res")
        pathUrl.appendPathComponent("values")
        
        var xmlUrl = pathUrl
        xmlUrl.appendPathComponent("strings.xml")
        if FileManager.default.fileExists(atPath:xmlUrl.path) {
            var jsonUrl = pathUrl
            jsonUrl.appendPathComponent("strings.json")
            
            // Convert XML to JSON
            // TODO: Replace with XMLCoder which is already used in S3!!!
            try runAndPrint(ThirdpartyUtilities.xml2jsonUrl.path, "-t", "xml2json", "-o", jsonUrl.path, xmlUrl.path)
            
            let strings = try ApkStrings.decode.fromJSON(file: jsonUrl)
            
            if let iconInfo: [String] = manifest?.manifest.application.nameAddress.components(separatedBy: "/"), iconInfo.count > 1 {
                appName = strings[iconInfo[1]]?.text
            }
        }
        
        if appName == nil {
            appName = file.lastPathComponent
        }
    }
    
    /// Parse additional application info
    private func getOtherApplicationInfo() throws {
        appIdentifier = manifest?.manifest.package
        versionLong = manifest?.manifest.platformBuildVersionName
        versionShort = manifest?.manifest.platformBuildVersionCode
    }
    
    /// Parse application icon info & icon itself
    private func getApplicationIcon() throws {
        appIconId = manifest?.manifest.application.icon
        if appIconId == nil {
            appIconId = manifest?.manifest.application.roundIcon
        }
        
        var pathUrl: URL = extractedApkFolder
        pathUrl.appendPathComponent("res")
        
        guard let iconInfo: [String] = appIconId?.replacingOccurrences(of: "@", with: "").components(separatedBy: "/") else {
            return
        }
        
        let folders: [String] = try FileManager.default.contentsOfDirectory(atPath: pathUrl.path).filter({ (folder) -> Bool in
            return folder.contains(iconInfo[0])
        }).sorted()
        for folder: String in folders {
            var iconBaseUrl: URL = pathUrl
            iconBaseUrl.appendPathComponent(folder)
            
            var iconUrl: URL = iconBaseUrl
            iconUrl.appendPathComponent(iconInfo[1])
            // QUESTION: Can this be uppercased after extraction?
            iconUrl.appendPathExtension("png")
            
            if FileManager.default.fileExists(atPath: iconUrl.path) {
                let data: Data = try Data(contentsOf: iconUrl)
                if data.count > (iconData?.count ?? 0) {
                    iconData = data
                }
            }
        }
    }
    
    private var appIconId: String?
    
    private var appNameId: String?
    
    /// Parse manifest file
    func parseManifest() throws {
        guard FileManager.default.fileExists(atPath: manifestFileUrl.path) else {
            throw Error.missingManifestFile
        }
        
        let xmlUrl = archive.appendingPathComponent("Decoded/AndroidManifest.xml")
        if FileManager.default.fileExists(atPath:xmlUrl.path) {
            let jsonUrl = archive.appendingPathComponent("Decoded/AndroidManifest.json")
            try runAndPrint(ThirdpartyUtilities.xml2jsonUrl.path, "-t", "xml2json", "-o", jsonUrl.path, xmlUrl.path)
            
            do {
                manifest = try ApkManifest.decode.fromJSON(file: jsonUrl)
            } catch {
                print("Apk error 179")
                dump(error)
                throw error
            }
        }
    }
    
    /// Process app
    func process(teamId: DbIdentifier, on req: Request) throws -> Future<App> {
        let promise = request.eventLoop.newPromise(App.self)
        
        DispatchQueue.global().async {
            do {
                // Extract archive
                try runAndPrint("java", "-jar", ThirdpartyUtilities.apkExtractorUrl.path.replacingOccurrences(of: "file://", with: ""), "d", "-sf", self.file.path, "-o", self.extractedApkFolder.path)
                
                // Parse manifest file
                try self.parseManifest()
                
                // Get info
                try self.getApplicationName()
                try self.getOtherApplicationInfo()
                try self.getApplicationIcon()
                
                // TODO: Make the following unblocking!!!
                let a = try self.app(platform: .android, teamId: teamId, on: req).wait()
                promise.succeed(result: a)
            } catch {
                print("Apk error 207")
                dump(error)
                promise.fail(error: error)
            }
        }
        
        return promise.futureResult
    }
    
}
