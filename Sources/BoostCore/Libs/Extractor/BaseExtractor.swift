//
//  Decoder.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 15/01/2018.
//

import Foundation
import Vapor
import ApiCore


class BaseExtractor {
    
    var request: Request
    
    var iconData: Data?
    var appName: String?
    var appIdentifier: String?
    var versionShort: String?
    var versionLong: String?
    var minSdk: String?
    
    var infoData: [String: Codable] = [:]
    
    var file: URL
    var archive: URL
    
    let createFolderStructure: Future<Void>
    
    // MARK: Initialization
    
    required init(file: URL, request req: Request) throws {
        self.request = req
        self.file = file
        
        self.archive = URL(fileURLWithPath: ApiCoreBase.configuration.storage.local.root)
            .appendingPathComponent(App.localTempAppFolder(on: req).relativePath)
        
        // TODO: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Following needs to be refactored so the structure 100% exists before we do anything else !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        self.createFolderStructure = try BoostCoreBase.tempFileHandler.createFolderStructure(url: self.archive, on: req)
    }
    
    static func decoder(file: String, platform: App.Platform, on req: Request) throws -> Extractor {
        let url = URL(fileURLWithPath: file)
        switch platform {
        case .ios:
            return try Ipa(file: url, request: req)
        case .android:
            return try Apk(file: url, request: req)
        default:
            throw ExtractorError.unsupportedFile
        }
    }
    
}
