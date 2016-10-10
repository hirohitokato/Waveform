//
//  DVGDiagramModel.swift
//  Waveform
//
//  Created by qqqqq on 17/04/16.
//  Copyright © 2016 developer. All rights reserved.
//

import Foundation
import UIKit

protocol DVGDiagramMovementsDelegate: class {
    func diagramDidSelect(_ dataRange: DataRange)
    func diagramMoved(scale: Double, start: Double)
}

class DVGAudioWaveformDiagramModel: DiagramModel, DVGDiagramDelegate {
    
    weak var movementsDelegate: DVGDiagramMovementsDelegate?
    
    var originalSelection: DataRange?
    
    func diagramDidSelect(_ dataRange: DataRange) {
        self.originalSelection = dataRange
        self.movementsDelegate?.diagramDidSelect(dataRange)
    }
    
    override func zoom(start: CGFloat, scale: CGFloat) {
        super.zoom(start: start, scale: scale)
        self.movementsDelegate?.diagramMoved(scale: self.geometry.scale, start: self.geometry.start)
    }
    override func moveToPosition(_ start: CGFloat) {
        super.moveToPosition(start)
        self.movementsDelegate?.diagramMoved(scale: self.geometry.scale, start: self.geometry.start)
    }
}
