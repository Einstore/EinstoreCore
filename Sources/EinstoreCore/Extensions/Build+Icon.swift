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
        guard let data = data, let hash = data.md5.asUTF8String() else {
            return req.eventLoop.newSucceededVoidFuture()
        }
        iconHash = hash
        return Build.query(on: req).filter(\Build.iconHash == hash).count().flatMap() { hashCount in
            guard hashCount == 0 else {
                return req.eventLoop.newSucceededVoidFuture()
            }
            guard let path = self.iconPath?.relativePath, let mime = data.imageFileMediaType() else {
                throw ExtractorError.errorSavingFile
            }
            let fm = try req.makeFileCore()
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
