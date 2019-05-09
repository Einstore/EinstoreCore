//
//  Build+Filename.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 21/02/2018.
//

import Foundation
import Vapor
import ApiCore


/// Helpers for Build
extension Build {
    
    /// Full download URL for file data
    public func fileUrl(token: String, on req: Request) -> URL {
        let serverUrl = req.serverURL()
        let url = serverUrl
            .appendingPathComponent("apps")
            .appendingPathComponent(id!.uuidString)
            .appendingPathComponent("file")
            .appendingPathComponent(token)
            .appendingPathComponent(fileName.safeText)
            .appendingPathExtension(platform.fileExtension)
        return url
    }
    
    /// Full icon url if exists
    public func iconUrl(on req: Request) -> URL? {
        guard hasIcon, let path = iconPath else {
            return nil
        }
        let serverUrl = req.serverURL()
        let url = serverUrl.appendingPathComponent(path.relativePath)
        return url
    }
    
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
    
    /// Target folder path (destination for the icons)
    public var iconsFolderPath: URL? {
        let path = URL(fileURLWithPath: EinstoreCoreBase.configuration.storage.appDestinationPath)
            .appendingPathComponent("icons")
        return path
    }
    
    /// Icon server path
    public var iconPath: URL? {
        guard let hash = iconHash else {
            return nil
        }
        let path = iconsFolderPath?.appendingPathComponent(hash).appendingPathExtension("png")
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
