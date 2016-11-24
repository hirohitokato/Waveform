//
//  DVGPlaybackPositionView.swift
//  Denoise
//
//  Created by developer on 29/01/16.
//  Copyright © 2016 DENIVIP Group. All rights reserved.
//

import UIKit

public
class PlaybackPositionView: UIView {
    
    let cursor = UIImageView(image: UIImage(named: "waweform-icon-button-play-slider"))
    
    init() {
        super.init(frame: .zero)
        self.isOpaque = false
        cursor.frame = CGRect(x: 0, y: 0, width: cursor.image!.size.width, height: cursor.image!.size.height);
        cursor.isHidden = true
        addSubview(cursor)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isOpaque = false
    }
    
    func positionCursor(){
        guard let relativePosition = self.position,
            relativePosition < 0 || relativePosition > 1
        else {
            cursor.isHidden = true
            return
        }
        
        cursor.isHidden = false
        
        let position = (self.bounds.width - lineWidth) * relativePosition + lineWidth/2
        
        cursor.center = CGPoint(x: position, y: center.y)
        
        self.setNeedsLayout()
    }
    
    /// Value from 0 to 1
    /// Setting value causes setNeedsDisplay method call
    /// Setting nil causes removing cursor
    var position: CGFloat? {
        didSet { self.positionCursor() }
    }
    var lineColor = UIColor.white
    var lineWidth: CGFloat = 2.0
}
