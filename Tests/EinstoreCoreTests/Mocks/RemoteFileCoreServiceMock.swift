//
//  RemoteFileCoreServiceMock.swift
//  EinstoreCoreTests
//
//  Created by Ondrej Rafaj on 10/05/2019.
//

import Foundation
import ApiCore
import FileCore


class RemoteFileCoreServiceMock: CoreManager, Service {
    
    struct File {
        let file: Data?
        let path: String
        let destination: String?
        let mime: MediaType?
    }
    
    var isRemote: Bool = true
    
    func serverUrl() throws -> URL? {
        return URL(string: "https://example.com")!
    }
    
    var savedFiles: [File] = []
    
    func save(file: Data, to path: String, mime: MediaType, on: Container) throws -> EventLoopFuture<Void> {
        savedFiles.append(File(file: file, path: path, destination: nil, mime: mime))
        print("Saving \(file.count) as \(mime) to \(path)")
        return on.eventLoop.newSucceededVoidFuture()
    }
    
    var copiedFiles: [File] = []
    
    func copy(file: String, to path: String, on: Container) throws -> EventLoopFuture<Void> {
        copiedFiles.append(File(file: nil, path: file, destination: path, mime: nil))
        print("Copy \(file) to \(path)")
        return on.eventLoop.newSucceededVoidFuture()
    }
    
    var movedFiles: [File] = []
    
    func move(file: String, to path: String, on: Container) throws -> EventLoopFuture<Void> {
        movedFiles.append(File(file: nil, path: file, destination: path, mime: nil))
        print("Move \(file) to \(path)")
        return on.eventLoop.newSucceededVoidFuture()
    }
    
    func get(file: String, on: Container) throws -> EventLoopFuture<Data> {
        print("Get \(file)")
        return on.eventLoop.newSucceededFuture(result: Data())
    }
    
    var deletedFiles: [File] = []
    
    func delete(file: String, on: Container) throws -> EventLoopFuture<Void> {
        movedFiles.append(File(file: nil, path: file, destination: nil, mime: nil))
        print("Delete \(file)")
        return on.eventLoop.newSucceededVoidFuture()
    }
    
    var exists: Bool = true
    
    func exists(file: String, on: Container) throws -> EventLoopFuture<Bool> {
        print("File \(file) \(exists ? "exists" : "doesn't exist")")
        return on.eventLoop.newSucceededFuture(result: exists)
    }
    
}
