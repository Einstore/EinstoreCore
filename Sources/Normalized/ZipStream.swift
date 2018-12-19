//
//  ZipStream.swift
//  Normalize
//
//  Created by Bopha Um on 2018/12/14.
//  Copyright © 2018 LiveUI. All rights reserved.
//

import Foundation
import Czlib

public class ZipStream {
    
    private static var c_version = zlibVersion()
    
    public enum Error: Int, Swift.Error {
        case streamEnd = 1
        case needDict = 2
        case errno = -1
        case stream = -2
        case data = -3
        case mem = -4
        case buf = -5
        case version = -6
        case unknown = 0
        
        static func makeError(res: CInt) -> Error? {
            return Error(rawValue: Int(res))
        }
    }
    
    private var strm = z_stream()
    
    public var deflater = true
    public var initd = false
    public var init2 = false
    public var level = Int32(-1)
    public var windowBits = Int32(15)
    public var out = [UInt8](repeating: 0, count: 5000)
    
    /// Public initializer
    public init() { }
    
    /// Write
    public func write(bytes : UnsafeMutablePointer<Bytef>, count: Int, flush: Bool) -> (bytes: [UInt8], err: Error?){
        var res : CInt
        if !initd {
            if deflater {
                if init2 {
                    res = deflateInit2_(&strm, level, 8, windowBits, 8, 0, ZipStream.c_version, CInt(MemoryLayout<z_stream>.size))
                } else {
                    res = deflateInit_(&strm, level, ZipStream.c_version, CInt(MemoryLayout<z_stream>.size))
                }
            } else {
                if init2 {
                    res = inflateInit2_(&strm, windowBits, ZipStream.c_version, CInt(MemoryLayout<z_stream>.size))
                } else {
                    res = inflateInit_(&strm, ZipStream.c_version, CInt(MemoryLayout<z_stream>.size))
                }
            }
            if res != 0 {
                return ([UInt8](), Error.makeError(res: res))
            }
            initd = true
        }
        var result = [UInt8]()
        strm.avail_in = CUnsignedInt(count)
        strm.next_in = bytes
        repeat {
            strm.avail_out = CUnsignedInt(out.count)
            strm.next_out = &out+0
            if deflater {
                res = deflate(&strm, flush ? 1 : 0)
            } else {
                res = inflate(&strm, flush ? 1 : 0)
            }
            if res < 0 {
                return ([UInt8](), Error.makeError(res: res))
            }
            let have = out.count - Int(strm.avail_out)
            if have > 0 {
                result += Array(out[0...have-1])
            }
        } while (strm.avail_out == 0 && res != 1)
        if strm.avail_in != 0 {
            return ([UInt8](), Error.makeError(res: -9999))
        }
        return (result, nil)
    }
    
    /// Destructor
    deinit {
        if initd {
            if deflater {
                deflateEnd(&strm)
            } else {
                inflateEnd(&strm)
            }
        }
    }
    
}

// MARK: - Deflate stream

public class DeflateStream : ZipStream {
    
    convenience public init(level : Int){
        self.init()
        super.level = CInt(level)
    }
    
    convenience public init(windowBits: Int){
        self.init()
        super.init2 = true
        super.windowBits = CInt(windowBits)
    }
    
    convenience public init(level : Int, windowBits: Int){
        self.init()
        super.init2 = true
        super.level = CInt(level)
        super.windowBits = CInt(windowBits)
    }
    
}

// MARK: - Inflate stream

public class InflateStream : ZipStream {
    
    override public init(){
        super.init()
        deflater = false
    }
    
    convenience public init(windowBits: Int){
        self.init()
        self.init2 = true
        self.windowBits = CInt(windowBits)
    }
    
}
