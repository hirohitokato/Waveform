//
//  Error.swift
//  Waveform
//
//  Created by developer on 11/04/16.
//  Copyright © 2016 developer. All rights reserved.
//

import Foundation

public
enum SamplesReaderError: Error {
    case NoSound
    case InvalidAudioFormat
    case CantReadSamples(NSError?)
    case UnknownError(NSError?)
    case SampleReaderNotReady
}

struct NoMoreSampleBuffersAvailable: Error {}
struct NoEnoughData: Error {}
