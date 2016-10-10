//
//  Plot.swift
//  Waveform
//
//  Created by developer on 18/12/15.
//  Copyright © 2015 developer. All rights reserved.
//

import UIKit.UIControl

@objc
public
class Plot: UIView {
    
    weak var dataSource: PlotDataSource? {
        didSet {
            identifier = dataSource?.identifier ?? ""
        }
    }
    
    var lineColor: UIColor = .black{
        didSet{
//            self.pathLayer.strokeColor = lineColor.CGColor
        }
    }

    var identifier: String = ""
    
    private var pathLayer: CAShapeLayer!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isOpaque = false
    }
    
    convenience init(){
        self.init(frame: .zero)
        self.isOpaque = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }
    
    func setupPathLayer() {
        
        self.pathLayer             = CAShapeLayer()
        self.pathLayer.strokeColor = UIColor.black.cgColor
        self.pathLayer.lineWidth   = 1.0
        self.layer.addSublayer(self.pathLayer)
        
        self.pathLayer.drawsAsynchronously = true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.redraw()
    }
    
    func redraw() {
        self.setNeedsDisplay()
    }
    
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setLineWidth(1/UIScreen.main.scale)
        context.addPath(self.newPathPart())
        context.setStrokeColor(self.lineColor.cgColor)
        context.interpolationQuality = .none
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        context.strokePath()
    }
    
    private func newPathPart() -> CGPath {
        
        let lineWidth: CGFloat = 1
        
        guard let dataSource = self.dataSource else {
            return CGMutablePath()
        }
        
        let currentCount = dataSource.pointsCount
        let sourceBounds = dataSource.dataSourceFrame.size
        
        let mPath        = CGMutablePath()
        mPath.move(to: CGPoint(x: 0,y: self.bounds.midY - lineWidth/2))
        
        let wProportion = self.bounds.size.width / sourceBounds.width
        let hPropostion = self.bounds.size.height / sourceBounds.height
        
        for index in 0..<currentCount {
            let point         = dataSource.pointAtIndex(index)
            let adjustedPoint = CGPoint(
                x: point.x * wProportion,
                y: point.y * hPropostion / 2.0)
            
            mPath.addLine(to: CGPoint(x: adjustedPoint.x, y: self.bounds.midY))
            mPath.addLine(to: CGPoint(x: adjustedPoint.x, y: self.bounds.midY - adjustedPoint.y))
            mPath.addLine(to: CGPoint(x: adjustedPoint.x, y: self.bounds.midY + adjustedPoint.y))
            mPath.addLine(to: CGPoint(x: adjustedPoint.x, y: self.bounds.midY))

        }
        
        mPath.addLine(to: CGPoint(x: 0.0,y: self.bounds.midY))
        mPath.closeSubpath()
        return mPath
    }
}


