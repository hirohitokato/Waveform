//
//  DVGAudioSource.swift
//  Waveform
//
//  Created by developer on 22/12/15.
//  Copyright © 2015 developer. All rights reserved.
//

import Foundation
import AVFoundation

struct Constants {
    static var DefaultAudioFormat = AudioFormat.init(samplesRate: 44100, bitsDepth: 16, numberOfChannels: 2)
}

@objc final
class AudioSamplesReader: NSObject {
    
    var asset: AVAsset
    init(asset: AVAsset) {
        self.asset = asset
        super.init()
    }
        
    private var readingRoutine: SamplesReadingRoutine?
    
    weak var samplesHandler: AudioSamplesHandler?
    
    var nativeAudioFormat: AudioFormat?
    var samplesReadAudioFormat = Constants.DefaultAudioFormat
    
    var progress = Progress()
    
    func readAudioFormat(completionBlock: @escaping (AudioFormat?, SamplesReaderError?) -> ()) {
        dispatch_asynch_on_global_processing_queue {
            do {
                self.nativeAudioFormat = try self.readAudioFormat()
                completionBlock(self.nativeAudioFormat, nil)
                
            } catch let error as SamplesReaderError {
                
                completionBlock(nil, error)
                
            } catch let error {
                
                fatalError("unknown error:\(error)")
            }
        }
    }
    
    func readAudioFormat() throws -> AudioFormat {
        
        guard let formatDescription = try? soundFormatDescription() else {
                throw SamplesReaderError.UnknownError(nil)
        }
        
#if DEBUG
        print("DEBUG Audio format description => \(formatDescription)")
#endif
        guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee
        else {
            throw SamplesReaderError.UnknownError(nil)
        }
        let format = AudioFormat(samplesRate: Int(asbd.mSampleRate), bitsDepth: Int(asbd.mBitsPerChannel), numberOfChannels: Int(asbd.mChannelsPerFrame))
        nativeAudioFormat = format
        return format
    }
    
    func assetAudioTrack() throws -> AVAssetTrack {
        guard let sound = asset.tracks(withMediaType: AVMediaTypeAudio).first else {
            throw SamplesReaderError.NoSound
        }
        return sound
    }
    
    func soundFormatDescription() throws -> CMAudioFormatDescription {
        guard let formatDescription = try assetAudioTrack().formatDescriptions.first else {
            throw SamplesReaderError.InvalidAudioFormat
        }
        return formatDescription as! CMAudioFormatDescription
    }

    private func audioReadingSettings(forFormat audioFormat: AudioFormat) -> [String: AnyObject] {
        return [
            AVFormatIDKey           : NSNumber(value: kAudioFormatLinearPCM),
            AVSampleRateKey         : audioFormat.samplesRate as AnyObject,
            AVNumberOfChannelsKey   : audioFormat.numberOfChannels as AnyObject,
            AVLinearPCMBitDepthKey  : (audioFormat.bitsDepth > 0 ? audioFormat.bitsDepth : 16) as AnyObject,
            AVLinearPCMIsBigEndianKey   : false as AnyObject,
            AVLinearPCMIsFloatKey       : false as AnyObject,
            AVLinearPCMIsNonInterleaved : false as AnyObject
        ]
    }

    func readSamples(_ audioFormat: AudioFormat? = nil, completion: @escaping (Error?) -> ()) {
        dispatch_asynch_on_global_processing_queue({
            try self.readSamples(audioFormat) }, onCatch: completion)
    }
    
    func readSamples(_ audioFormat: AudioFormat? = nil) throws {
        if let format = audioFormat {
            samplesReadAudioFormat = format
        }
        try self.prepareForReading()
        try self.read()
    }

    private func prepareForReading() throws {
        
        let sound = try assetAudioTrack()
        
        let assetReader: AVAssetReader
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch let error as NSError {
            throw SamplesReaderError.UnknownError(error)
        }
    
        let settings = audioReadingSettings(forFormat: samplesReadAudioFormat)
        
        let readerOutput = AVAssetReaderTrackOutput(track: sound, outputSettings: settings)
        
        assetReader.add(readerOutput)
        assetReader.timeRange = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
        
        if samplesHandler == nil {
            print("\(#function)[\(#line)] Caution!!! There is no samples handler")
        }

        self.readingRoutine = SamplesReadingRoutine(assetReader: assetReader, readerOutput: readerOutput, audioFormat: samplesReadAudioFormat, samplesHandler: samplesHandler, progress: self.progress)
    }
    
    private func read() throws {
        
        guard let readingRoutine = readingRoutine else {
            throw SamplesReaderError.SampleReaderNotReady
        }
        try readingRoutine.readSamples()
    }
}

final class SamplesReadingRoutine {
    
    let assetReader: AVAssetReader
    let readerOutput: AVAssetReaderOutput
    let audioFormat: AudioFormat
    weak var samplesHandler: AudioSamplesHandler?

    let progress: Progress

    lazy var estimatedSamplesCount: Int = {
        return Int(self.assetReader.asset.duration.seconds * Double(self.audioFormat.samplesRate))
    }()
    
    init(assetReader: AVAssetReader, readerOutput: AVAssetReaderOutput, audioFormat: AudioFormat, samplesHandler: AudioSamplesHandler?, progress: Progress) {
        self.assetReader  = assetReader
        self.readerOutput = readerOutput
        self.audioFormat  = audioFormat
        self.samplesHandler = samplesHandler
        self.progress = progress
        progress.totalUnitCount = Int64(self.estimatedSamplesCount)
    }
    
    var isReading: Bool {
        return assetReader.status == .reading
    }
    
    func startReading() throws  {
        if !assetReader.startReading() {
            throw SamplesReaderError.CantReadSamples(assetReader.error as NSError?)
        }
    }

    func cancelReading() {
        assetReader.cancelReading()
    }
    
    func readSamples() throws {
        self.samplesHandler?.willStartReadSamples(estimatedSampleCount: estimatedSamplesCount)
        try startReading()
        while isReading {
            do {
                try readNextSamples()
            } catch (_ as NoMoreSampleBuffersAvailable) {
                break
            } catch {
                cancelReading()
                throw error
            }
        }
        try checkStatusOfAssetReaderOnComplete()
        self.samplesHandler?.didStopReadSamples(count: Int(self.progress.completedUnitCount))
    }
    
    func readNextSamples() throws {
        guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
            throw NoMoreSampleBuffersAvailable()
        }
        
        // Get buffer
        guard let buffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            throw SamplesReaderError.UnknownError(nil)
        }
        
        let length = CMBlockBufferGetDataLength(buffer)
        
        // Append new data
        let tempBytes = UnsafeMutableRawPointer.allocate(bytes: length, alignedTo: 0)
        var returnedPointer: UnsafeMutablePointer<Int8>?
    
        if CMBlockBufferAccessDataBytes(buffer, 0, length, tempBytes, &returnedPointer) != kCMBlockBufferNoErr {
            throw NoEnoughData()
        }
        
        tempBytes.deallocate(bytes: length, alignedTo: 0)
        
        guard (returnedPointer != nil) else {
            throw SamplesReaderError.UnknownError(nil)
        }
    
        let samplesContainer = AudioSamplesContainer(buffer: returnedPointer!, length: length, numberOfChannels: audioFormat.numberOfChannels)
        samplesHandler?.handleSamples(samplesContainer)
        progress.completedUnitCount += samplesContainer.samplesCount
    }
    
    func checkStatusOfAssetReaderOnComplete() throws {
        switch assetReader.status {
        case .unknown, .failed, .reading:
            throw SamplesReaderError.UnknownError(assetReader.error as NSError?)
        case .cancelled, .completed:
            return
        }
    }
}
