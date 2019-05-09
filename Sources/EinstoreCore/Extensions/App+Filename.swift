//
//  App+Filename.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 21/02/2018.
//

import Foundation
import Vapor
import ApiCore


/// Helpers for App
extension Build {
    
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
        // TODO: This would probably deserve a little refactor!
        let path = URL(fileURLWithPath: EinstoreCoreBase.configuration.storage.appDestinationPath)
            .appendingPathComponent(created.dateFolderPath)
            .appendingPathComponent(id.uuidString)
        return path
    }
    
    /// Icon server path
    public var iconPath: URL? {
        let path = targetFolderPath?.appendingPathComponent(iconName)
        return path
    }
    
    /// App file path
    public var appPath: URL? {
        let path = targetFolderPath?.appendingPathComponent(fileName)
        return path
    }
    
    /// Temporary app folder
    public static func localTempAppFolder(on req: Request) -> URL {
        let path = URL(fileURLWithPath: EinstoreCoreBase.configuration.storage.rootTempPath)
            .appendingPathComponent(req.sessionId.uuidString)
        return path
    }
    
    /// Temporary app filepath
    public static func localTempAppFile(on req: Request) -> URL {
        let path = localTempAppFolder(on: req).appendingPathComponent("tmp.boost")
        return path
    }
    
}
