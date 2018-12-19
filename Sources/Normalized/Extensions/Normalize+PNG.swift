//
//  Normalize+PNG.swift
//  Normalize
//
//  Created by Ondrej Rafaj on 19/12/2018.
//  Copyright © 2018 LiveUI. All rights reserved.
//

import Foundation
import Czlib


extension Normalize {
    
    static let pngHeader = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]
    
    public static var maxDecodeSize = 160000000 // 160 M
    
    public static func getNormalizedPNG(file: URL) throws -> Data {
        guard let data = try? Data(contentsOf: file) else {
            throw Error.fileDoesntExist
        }
        
        return try getNormalizedPNG(data: data)
    }
    
    public static func getNormalizedPNG(file: String) throws -> Data {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            throw Error.fileDoesntExist
        }
        
        return try getNormalizedPNG(data: data)
    }
    
    public static func getNormalizedPNG(data: Data) throws -> Data {
        var outData = Data()
        var pos = 0
        if data.count < 8 {
            throw Error.emptyFile
        }
        
        // Check PNG Header
        var bytes = [UInt8](data)
        
        var idatAcc = [UInt8]()
        var breakLoop = false
        if (!bytes[0...7].elementsEqual(pngHeader, by: {$0 == $1})) {
            throw Error.invalidFile
        }
        outData.append(contentsOf: bytes[0...7])
        pos += 8
        
        var width:Int = 0
        var height:Int = 0
        var chunkPos = 0
        var dataPos = 0
        
        // For Each Chunk is th PNG File
        while pos < data.count {
            var skip = false
            
            // Reading Chunk
            chunkPos = pos
            let chunkLen = Int(bytes[pos]) << 24 + Int(bytes[pos + 1]) << 16 + Int(bytes[pos + 2]) << 8 + Int(bytes[pos + 3])
            pos += 4
            var chunkType = String(bytes: bytes[pos..<pos+4], encoding: .utf8)
            pos += 4
            dataPos = pos
            
            // CRC
            pos += chunkLen + 4
            
            if (chunkType == "IHDR") { // Parsing Header Cunk
                width = Int(bytes[dataPos]) << 24 +
                    Int(bytes[dataPos + 1]) << 16 +
                    Int(bytes[dataPos + 2]) << 8 +
                    Int(bytes[dataPos + 3])
                height = Int(bytes[dataPos + 4]) << 24 +
                    Int(bytes[dataPos + 5]) << 16 +
                    Int(bytes[dataPos + 6]) << 8 +
                    Int(bytes[dataPos + 7])
            }
            if chunkType == "IDAT" { // Parsing the image chunk
                idatAcc.append(contentsOf: bytes[dataPos..<dataPos + chunkLen])
                skip = true
            }
            if chunkType == "CgBI" { // Removing CGBI chunk
                skip = true
            }
            if chunkType == "IEND" { // Add all accumulated IDATA chunks
                let bufsize = width * height * 4 + height
                let idatAccPointer = UnsafeMutablePointer<UInt8>(&idatAcc)
                let originData = InflateStream(windowBits: -15).write(bytes: idatAccPointer, count: idatAcc.count, flush: true)
                
                if originData.bytes.count == 0 {
                    throw Error.invalidFile
                }
                var newData = [UInt8]()
                var i = 0
                for _ in 0..<height {
                    i = newData.count
                    newData.append(originData.bytes[i])
                    for _ in 0..<width{
                        i = newData.count
                        newData.append(originData.bytes[i+2])
                        newData.append(originData.bytes[i+1])
                        newData.append(originData.bytes[i+0])
                        newData.append(originData.bytes[i+3])
                    }
                }
                
                let newDataPointer = UnsafeMutablePointer<UInt8>(&newData)
                
                let result = DeflateStream().write(bytes: newDataPointer, count: bufsize, flush: true)
                
                if let err = result.err {
                    throw err
                }
                
                let codedCount = result.bytes.count
                
                chunkType = "IDAT"
                var crc = crc32(0, chunkType, 4)
                crc = crc32(crc, result.bytes, uInt(codedCount))
                
                var count = Int32(codedCount).bigEndian
                outData.append(UnsafeBufferPointer(start: &count, count: 1))
                outData.append(chunkType?.data(using: String.Encoding.utf8) ?? Data())
                outData.append(contentsOf: result.bytes)
                var bigEndianCRC = UInt32(Int(crc)).bigEndian
                outData.append(UnsafeBufferPointer(start: &bigEndianCRC, count: 1))
                
                skip = true
                breakLoop = true
            }
            
            if !skip {
                outData.append(contentsOf: bytes[chunkPos..<pos])
            }
            
            if breakLoop {
                break
            }
        }
        return outData
    }
    
}

