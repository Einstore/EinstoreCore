//
//  BuildPlist.swift
//  ApiCore
//
//  Created by Ondrej Rafaj on 22/02/2018.
//

import Foundation
import Vapor
import ErrorsCore


/// Applications Info.plist data struct
public struct BuildPlist: Codable {
    
    public struct Item: Codable {
        
        public struct Asset: Codable {
            
            let kind: String = "software-package"
            let url: String
            
            public init(build: Build, token: String, request req: Request) throws {
                self.url = build.fileUrl(token: token, on: req).absoluteString
            }
            
        }
        
        public struct Metadata: Codable {
            
            let bundleIdentifier: String
            let bundleVersion: String
            let kind: String = "software"
            let title: String
            
            enum CodingKeys: String, CodingKey {
                case bundleIdentifier = "bundle-identifier"
                case bundleVersion = "bundle-version"
                case kind
                case title
            }
            
            public init(build: Build) {
                self.bundleIdentifier = build.identifier
                self.bundleVersion = build.version
                self.title = build.name
            }
            
        }
        
        let assets: [Asset]
        let metadata: Metadata
        
        public init(build: Build, token: String, request req: Request) throws {
            self.assets = [
                try Asset(build: build, token: token, request: req)
            ]
            self.metadata = Metadata(build: build)
        }
        
    }
    
    let items: [Item]
    
    public init(build: Build, token: String, request req: Request) throws {
        self.items = [
            try Item(build: build, token: token, request: req)
        ]
    }
    
}
