//
//  AudioSamplesContainer.swift
//  Waveform
//
//  Created by developer on 11/04/16.
//  Copyright © 2016 developer. All rights reserved.
//

import Foundation

struct AudioSamplesContainer {
    let buffer: UnsafePointer<Int16>
    let samplesCount: Int
    let numberOfChannels: Int
    
    init<T>(buffer: UnsafePointer<T>, length: Int, numberOfChannels: Int) {

        self.buffer           = UnsafeRawPointer(buffer).assumingMemoryBound(to: Int16.self)
        self.samplesCount     = length * MemoryLayout<T>.size/MemoryLayout<Int16>.size / numberOfChannels
        self.numberOfChannels = numberOfChannels
    }
    
    func sample(channelIndex: Int, sampleIndex: Int) -> Int16 {
        assert(channelIndex < numberOfChannels)
        assert(sampleIndex < samplesCount)
        return buffer[numberOfChannels * sampleIndex + channelIndex]
    }
}
