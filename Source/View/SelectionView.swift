//
//  SelectionView.swift
//  Waveform
//
//  Created by developer on 26/01/16.
//  Copyright © 2016 developer. All rights reserved.
//

import UIKit

@objc
public
class SelectionView: UIView {
    
    let sliderIcon = UIImage(named: "waweform-icon-button-selection", in: Bundle(for: SelectionView.self), compatibleWith: nil)!
    var sliderSize: CGSize = .zero
    let leftSlider = CALayer()
    let rightSlider = CALayer()
    var selectionLayer: CALayer!
    
    init() {
        super.init(frame: .zero)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.setupSelectionLayer()
        self.backgroundColor = .clear
        
        leftSlider.contents = sliderIcon.cgImage
        rightSlider.contents = sliderIcon.cgImage
        sliderSize = CGSize(width: sliderIcon.size.width/2.0, height: sliderIcon.size.height/2.0)
        
        self.layer.addSublayer(leftSlider)
        self.layer.addSublayer(rightSlider)
    }
    
    func setupSelectionLayer() {
        let layer             = CALayer()

        layer.cornerRadius    = 5.0
        layer.borderWidth     = 0.0
        layer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        self.layer.addSublayer(layer)
        self.selectionLayer   = layer
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.layoutSelection(self.selection)
    }
    
    var selection: DataRange? {
        didSet{ self.layoutSelection(selection) }
    }
    
    func layoutSelection(_ dataRange: DataRange?) {
        
        guard let dataRange = dataRange else {
            self.selectionLayer.backgroundColor = UIColor.clear.cgColor
            return
        }
        self.selectionLayer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        
        let startLocation  = self.bounds.width * CGFloat(dataRange.location)
        let selectionWidth = self.bounds.width * CGFloat(dataRange.length)
        
        
        if selectionWidth < sliderSize.width * 2 {
            let opacity = max(Float((selectionWidth - sliderSize.width)/sliderSize.width), 0)
            leftSlider.opacity = opacity
            rightSlider.opacity = opacity
        } else {
            leftSlider.opacity = 1
            rightSlider.opacity = 1
        }
        
        let frame = CGRect(x: startLocation, y: 0, width: selectionWidth, height: self.bounds.height)
        let leftSliderFrame = CGRect(x: startLocation - sliderSize.width/2,
                                     y: self.center.y - sliderSize.height/2,
                                     width: sliderSize.width,
                                     height: sliderSize.height)
        let rightSliderFrame = CGRect(x: startLocation + selectionWidth - sliderSize.width/2,
                                      y: self.center.y - sliderSize.height/2,
                                      width: sliderSize.width,
                                      height: sliderSize.height)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.selectionLayer.frame = frame
        leftSlider.frame = leftSliderFrame
        rightSlider.frame = rightSliderFrame
        CATransaction.commit()
    }
}
