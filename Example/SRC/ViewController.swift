//
//  ViewController.swift
//  Waveform
//
//  Created by developer on 18/12/15.
//  Copyright © 2015 developer. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, DVGDiagramMovementsDelegate {

    var phAsset: PHAsset?
    @IBOutlet weak var waveformContainerView: UIView!
    var waveform: DVGWaveformController!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Waveform Instatiation
        self.waveform = DVGWaveformController(containerView: self.waveformContainerView)
        
        // Get AVAsset from PHAsset
        if let phAsset = self.phAsset {
            let options = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {_ in return false}
            
            phAsset.requestContentEditingInput(with: options) { contentEditingInput, info in
                print(contentEditingInput, info)
                DispatchQueue.main.async {
                    if let asset = contentEditingInput?.avAsset {
                        self.waveform.asset = asset
                        self.configureWaveform()
                    } else {
                        print(info[PHContentEditingInputResultIsInCloudKey])
                        if let value = info[PHContentEditingInputResultIsInCloudKey] as? Int, value == 1 {
                            self.showAlert("Load video from iCloud first")
                        } else {
                            self.showAlert("Can't get audio from this video.")
                        }
                    }
                }
            }
        }
    }
    
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func configureWaveform() {
        self.waveform.movementDelegate = self
        let waveform1 = self.waveform.maxValuesWaveform()
        waveform1?.lineColor = UIColor.red
        
        let waveform2 = self.waveform.avgValuesWaveform()
        waveform2?.lineColor = UIColor.green
        self.waveform.numberOfPointsOnThePlot = 2000
    }
    
    func diagramDidSelect(_ dataRange: DataRange) {
        print("\(#function), dataRange: \(dataRange)")
    }
    
    func diagramMoved(scale: Double, start: Double) {
        print("\(#function), scale: \(scale), start: \(start)")
    }
    
    @IBAction func readAudioAndDrawWaveform() {
        self.waveform.readAndDrawSynchronously({[weak self] in
            if $0 != nil {
                print("error:", $0!)
                self?.showAlert("Can't read asset")
            } else {
                print("waveform finished drawing")
            }
        })
    }
}
