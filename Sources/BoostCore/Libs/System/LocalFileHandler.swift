//
//  LocalFileHandler.swift
//  BoostCore
//
//  Created by Ondrej Rafaj on 07/04/2018.
//

import Foundation
import Vapor


public class LocalFileHandler: FileHandler {
    
    public static var `default`: FileHandler = LocalFileHandler()
    
    public func createFolderStructure(path: String, on req: Request) throws -> Future<Void> {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func createFolderStructure(url: URL, on req: Request) throws -> Future<Void> {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func delete(path: String, on req: Request) throws -> Future<Void> {
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func delete(url: URL, on req: Request) throws -> Future<Void> {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func save(data: Data, to path: String, on req: Request) throws -> Future<Void> {
        try data.write(to: URL(fileURLWithPath: path))
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func save(data: Data, to path: URL, on req: Request) throws -> Future<Void> {
        try data.write(to: path)
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func move(from: String, to: String, on req: Request) throws -> Future<Void> {
        try FileManager.default.moveItem(atPath: from, toPath: to)
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func move(from: URL, to: URL, on req: Request) throws -> Future<Void> {
        try FileManager.default.moveItem(at: from, to: to)
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func copy(from: String, to: String, on req: Request) throws -> Future<Void> {
        try FileManager.default.copyItem(atPath: from, toPath: to)
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    public func copy(from: URL, to: URL, on req: Request) throws -> Future<Void> {
        try FileManager.default.copyItem(at: from, to: to)
        return req.eventLoop.newSucceededFuture(result: Void())
    }
    
    // MARK: Initialization
    
    public init() {
        
    }
    
}
