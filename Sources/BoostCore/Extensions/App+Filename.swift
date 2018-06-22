//
//  App+Filename.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 21/02/2018.
//

import Foundation
import Vapor


/// Helpers for App
extension App {
    
    /// Default icon name
    public var iconName: String {
        return "icon.png"
    }
    
    /// Filename
    public var fileName: String {
        return "app.\(platform.fileExtension)"
    }
    
    /// Target folder path (destination for the file)
    public var targetFolderPath: URL? {
        guard let id = self.id else {
            return nil
        }
        
        return URL(fileURLWithPath: "/Apps")
            .appendingPathComponent(created.dateFolderPath)
            .appendingPathComponent(id.uuidString)
    }
    
    /// Icon server path
    public var iconPath: URL? {
        return targetFolderPath?.appendingPathComponent(iconName)
    }
    
    /// App file path
    public var appPath: URL? {
        return targetFolderPath?.appendingPathComponent(fileName)
    }
    
    /// Temporary app folder
    public static func tempAppFolder(on req: Request) -> URL {
        return URL(fileURLWithPath: "/tmp/Boost").appendingPathComponent(req.sessionId.uuidString)
    }
    
    /// Temporary app filepath
    public static func tempAppFile(on req: Request) -> URL {
        return tempAppFolder(on: req).appendingPathComponent("tmp.boost")
    }
    
}
