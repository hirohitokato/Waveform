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
        
        let frame = CGRect(x: startLocation, y: 0, width: selectionWidth, height: self.bounds.height)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.selectionLayer.frame = frame
        CATransaction.commit()
    }
}
