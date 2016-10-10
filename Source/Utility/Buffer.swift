//
//  Buffer.swift
//  Channel Performance test
//
//  Created by developer on 15/04/16.
//  Copyright © 2016 developer. All rights reserved.
//

import Foundation

public
class Buffer {
    typealias DefaultNumberType = Double
    var maxValue = -Double.infinity
    var minValue = Double.infinity
    var count = 0
    var buffer: UnsafeMutableRawPointer?
    var _buffer: UnsafeMutablePointer<DefaultNumberType>?
    fileprivate var space = 0

    func append(value: Double) {
        if maxValue < value { maxValue = value }
        if minValue > value { minValue = value }
        
        if space == count {
            let newSpace = max(space * 2, 16)
            self.moveSpace(to: newSpace)
            _buffer = UnsafeMutablePointer<DefaultNumberType>(buffer?.assumingMemoryBound(to: DefaultNumberType.self))
        }
        (UnsafeMutablePointer<DefaultNumberType>((buffer?.assumingMemoryBound(to: DefaultNumberType.self))!) + count).initialize(to: value)
        count += 1
    }
    fileprivate
    func moveSpace(to newSpace: Int) {
        let newPtr = UnsafeMutablePointer<DefaultNumberType>.allocate(capacity: newSpace)
        
        newPtr.moveInitialize(from: UnsafeMutablePointer<DefaultNumberType>((buffer?.assumingMemoryBound(to: DefaultNumberType.self))!), count: count)
        
        buffer?.deallocate(bytes: count, alignedTo: 0)
        
        buffer = UnsafeMutableRawPointer(newPtr)
        space = newSpace
    }
    
    subscript(index: Int) -> Double {
        return _buffer?[index] ?? Double.infinity
    }
    
    func value(atIndex index: Int) -> Double {
        return _buffer?[index] ?? Double.infinity
    }
}

final
class GenericBuffer<T: NumberType>: Buffer {
    var __buffer: UnsafeMutablePointer<T>?

    override final func append(value: Double) {
        

        if maxValue < value { maxValue = value }
        if minValue > value { minValue = value }
        
        if space == count {
            let newSpace = max(space * 2, 16)
            self.moveSpace(to: newSpace)
        }
        guard (__buffer != nil) else {return}
        (__buffer! + count).initialize(to: T(value))
        count += 1
    }
    
    override final func moveSpace(to newSpace: Int) {
        
        let newPtr = UnsafeMutablePointer<T>.allocate(capacity: newSpace)
        
        if (__buffer == nil){
            __buffer = newPtr
        } else {
            newPtr.moveInitialize(from: __buffer!, count: count)
            __buffer!.deallocate(capacity: count)
            __buffer = newPtr
        }
        space = newSpace
    }
    
    override subscript(index: Int) -> Double {
        return __buffer?[index].double ?? Double.infinity
    }
    
    deinit {
        __buffer?.deinitialize(count: space)
        __buffer?.deallocate(capacity: space)
    }
}
