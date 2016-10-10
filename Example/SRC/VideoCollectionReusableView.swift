//
//  VideoCollectionReusableView.swift
//  Waveform
//
//  Created by qqqqq on 18/04/16.
//  Copyright © 2016 developer. All rights reserved.
//

import UIKit
import Photos

class VideoCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.titleLabel.adjustsFontSizeToFitWidth    = true
        self.subtitleLabel.adjustsFontSizeToFitWidth = true
        self.dateLabel.adjustsFontSizeToFitWidth     = true
        
        self.titleLabel.text    = nil;
        self.subtitleLabel.text = nil;
        self.dateLabel.text     = nil;
    }
    
    override func prepareForReuse() {
        super.prepareForReuse();
    
        self.titleLabel.text    = nil;
        self.subtitleLabel.text = nil;
        self.dateLabel.text     = nil;
    }
    
    func configureWithCollection(collection: PHAssetCollection) {
        
        if collection.localizedTitle != nil {
            self.titleLabel.text = collection.localizedTitle
        }
        
        if collection.localizedLocationNames.count > 0 {
            if self.titleLabel.text != nil {
                self.subtitleLabel.text = collection.localizedLocationNames.first
            } else {
                self.titleLabel.text = collection.localizedLocationNames.first
            }
        }
        
        let date = DateFormatter.localizedString(from: collection.startDate!, dateStyle:.long, timeStyle:.none)
        
        if self.titleLabel.text != nil {
            self.dateLabel.text = date
        } else {
            self.titleLabel.text = date;
        }
        
        self.layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        self.titleLabel.sizeToFit()
        self.subtitleLabel.sizeToFit()
        self.dateLabel.sizeToFit()
    
        let titleLabelTopOffsetWithNoSubtitle: CGFloat = 10;
        
        let titleLabelTopOffset: CGFloat       = 20;
        let subtitleLabelBottomOffset: CGFloat = 10;
        let horizontalBordersOffset: CGFloat   = 15;
        let dateLabelWidth: CGFloat            = 100 - horizontalBordersOffset;
    
        if (self.subtitleLabel.text?.characters.count == 0) {
    
            self.titleLabel.frame = CGRect(origin: CGPoint(x: horizontalBordersOffset,
                                                           y: titleLabelTopOffsetWithNoSubtitle ),
                                             size: CGSize(width: self.bounds.width - dateLabelWidth,
                                                        height: self.bounds.height - titleLabelTopOffsetWithNoSubtitle ))
            
            
            
            self.dateLabel.frame  = CGRect( origin: CGPoint(x: self.bounds.width - dateLabelWidth - horizontalBordersOffset,
                                                            y: 0 + titleLabelTopOffsetWithNoSubtitle ),
                                              size: CGSize(width: dateLabelWidth,
                                                         height: self.bounds.height - titleLabelTopOffsetWithNoSubtitle ))
            
        } else {
            self.titleLabel.frame    = CGRect( origin: CGPoint(x: horizontalBordersOffset,
                                                               y: titleLabelTopOffset ),
                                                 size: CGSize(width: self.bounds.width - dateLabelWidth - 2 * horizontalBordersOffset,
                                                            height: self.titleLabel.bounds.height ))
            
            self.subtitleLabel.frame = CGRect( origin: CGPoint(x: horizontalBordersOffset,
                                                               y: self.bounds.height - subtitleLabelBottomOffset - self.subtitleLabel.bounds.height ),
                                                 size: CGSize(width: self.bounds.width - dateLabelWidth - 2 * horizontalBordersOffset,
                                                               height: self.subtitleLabel.bounds.height))
            
            self.dateLabel.frame     = CGRect( origin: CGPoint(x: self.bounds.width - dateLabelWidth - horizontalBordersOffset,
                                                               y: titleLabelTopOffset ),
                                                  size: CGSize(width:  dateLabelWidth,
                                                               height: self.dateLabel.bounds.height ))
        }
    }
}
