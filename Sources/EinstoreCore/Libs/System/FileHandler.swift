//
//  FileHandler.swift
//  EinstoreCore
//
//  Created by Ondrej Rafaj on 08/03/2018.
//

import Foundation
import Vapor


public protocol FileHandler {
    static var `default`: FileHandler { get }
    
    func createFolderStructure(path: String, on: Request) throws -> Future<Void>
    func createFolderStructure(url: URL, on: Request) throws -> Future<Void>
    
    func delete(path: String, on: Request) throws -> Future<Void>
    func delete(url: URL, on: Request) throws -> Future<Void>
    
    func save(data: Data, to: String, on: Request) throws -> Future<Void>
    func save(data: Data, to: URL, on: Request) throws -> Future<Void>
    
    func move(from: String, to: String, on: Request) throws -> Future<Void>
    func move(from: URL, to: URL, on: Request) throws -> Future<Void>
    
    func copy(from: String, to: String, on: Request) throws -> Future<Void>
    func copy(from: URL, to: URL, on: Request) throws -> Future<Void>
}
