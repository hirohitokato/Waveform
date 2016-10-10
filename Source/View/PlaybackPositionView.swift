//
//  DVGPlaybackPositionView.swift
//  Denoise
//
//  Created by developer on 29/01/16.
//  Copyright © 2016 DENIVIP Group. All rights reserved.
//

import UIKit

class PlaybackPositionView: UIView {
    
    init() {
        super.init(frame: .zero)
        self.isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let relativePosition = self.position else {
            return
        }
        
        if relativePosition < 0 || relativePosition > 1 {
            return
        }
        
        let position = (self.bounds.width - lineWidth) * relativePosition + lineWidth/2
        
        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError("No context")
        }
        
        context.setStrokeColor(self.lineColor.cgColor)
        context.setLineWidth(lineWidth)
        
        
        
        let cursor = CGMutablePath()
        
        cursor.move(to: CGPoint(x:position,y:0))
        cursor.addLine(to: CGPoint(x:position,y:self.bounds.height))
        context.addPath(cursor)
        
        context.strokePath()
        
    }
    
    /// Value from 0 to 1
    /// Setting value causes setNeedsDisplay method call
    /// Setting nil causes removing cursor
    var position: CGFloat? {
        didSet { self.setNeedsDisplay() }
    }
    var lineColor = UIColor.white
    var lineWidth: CGFloat = 2.0
}
