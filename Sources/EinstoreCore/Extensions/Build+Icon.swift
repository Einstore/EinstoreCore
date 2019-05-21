//
//  Build+Icon.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 09/05/2019.
//

import Foundation
import Vapor
import Fluent


extension Build {
    
    public func save(iconData data: Data?, on req: Request) throws -> EventLoopFuture<Void> {
        guard let data = data else {
            return req.eventLoop.newSucceededVoidFuture()
        }
        iconHash = try data.asMD5String()
        let fm = try req.makeFileCore()
        guard let path = self.iconPath?.relativePath, let mime = data.imageFileMediaType() else {
            throw ExtractorError.errorSavingFile
        }
        return try fm.exists(file: path, on: req).flatMap() { exists in
            guard !exists else {
                return req.eventLoop.newSucceededVoidFuture()
            }
            return try fm.save(file: data, to: path, mime: mime, on: req)
        }
    }
    
    public func getIcon(on req: Request) throws -> EventLoopFuture<BuildIcon> {
        fatalError()
    }
    
    public func deleteIcon(on req: Request) throws -> EventLoopFuture<Void> {
        guard let hash = iconHash else {
            return req.eventLoop.newSucceededVoidFuture()
        }
        return Build.query(on: req).filter(\Build.iconHash == hash).count().flatMap() { hashCount in
            guard hashCount <= 1 else {
                return req.eventLoop.newSucceededVoidFuture()
            }
            
            guard let path = self.iconPath?.relativePath else {
                throw ExtractorError.errorSavingFile
            }
            let fm = try req.makeFileCore()
            return try fm.delete(file: path, on: req)
        }
    }
    
}
