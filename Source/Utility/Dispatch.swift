//
//  Dispatch.swift
//  Waveform
//
//  Created by developer on 13/04/16.
//  Copyright © 2016 developer. All rights reserved.
//

import Foundation

let processingQueue = DispatchQueue(label: "ru.denivip.waveform.processing")// dispatch_queue_create("ru.denivip.waveform.processing", DISPATCH_QUEUE_SERIAL)

public func dispatch_asynch_on_global_processing_queue(block: @escaping ()->() ) {
    
    
    
    if processingQueue.label == String(cString:__dispatch_queue_get_label(nil),encoding: .utf8) {
        autoreleasepool(invoking: block)
    } else {
        processingQueue.async(execute: block)
    }
}

public func dispatch_asynch_on_global_processing_queue(_ body: @escaping () throws -> (), onCatch: @escaping (Error?) -> ()) {
    dispatch_asynch_on_global_processing_queue {
        do {
            try body()
            onCatch(nil)
        }
        catch {
            onCatch(error)
        }
    }
}
