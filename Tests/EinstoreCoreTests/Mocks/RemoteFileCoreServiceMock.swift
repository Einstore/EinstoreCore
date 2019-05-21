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
        return isRemote ? URL(string: "https://example.com")! : nil
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
    
    var getFile: Data? = nil
    
    func get(file: String, on: Container) throws -> EventLoopFuture<Data> {
        let data = getFile ?? savedFiles.first(where: { $0.path == file })?.file ?? Data()
        print("Get \(file)")
        return on.eventLoop.newSucceededFuture(result: data)
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


extension Array where Element == RemoteFileCoreServiceMock.File {
    
    func icon(hash: String) -> Element? {
        return first(where: { $0.path == "apps/icons/\(hash).png" })
    }
    
}
