//
//  DVGWaveformView.swift
//  Waveform
//
//  Created by developer on 22/01/16.
//  Copyright © 2016 developer. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

/// Entry point for Waveform UI Component
/// Creates all needed data sources, view models and views and sets needed dependencies between them
/// By default draws waveforms for max values and average values (see. LogicProvider class)
public
class DVGWaveformController: NSObject {

    //MARK: - Initialization

    convenience init(containerView: UIView) {
        self.init()
        self.addPlotViewToContainerView(containerView)
    }
    override init() {
        super.init()
    }

    deinit {
        self.diagram?.removeFromSuperview()
    }
    
    //MARK: -
    //MARK: - Configuration
    //MARK: - Internal configuration
    func addPlotViewToContainerView(_ containerView: UIView) {
        let diagram = DVGAudioWaveformDiagram()
        
        diagram.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(diagram)
        diagram.attachBoundsOfSuperview()
        
        self.diagram = diagram
    }
    
    func configure() {
        waveformDataSource.neededSamplesCount = numberOfPointsOnThePlot
        // Prepare Plot Model with DataSource
        self.addDataSource(waveformDataSource)
        self.diagramViewModel.channelsSource = channelSourceMapper
        
        // Set plot model to plot view
        diagram?.delegate = diagramViewModel
        diagram?.dataSource = diagramViewModel
        
        diagramViewModel.movementsDelegate = self
    }
    
    //MARK: - For external configuration
    func waveformWithIdentifier(_ identifier: String) -> Plot? {
        return self.diagram?.waveformDiagramView.plotWithIdentifier(identifier)
    }

    func maxValuesWaveform() -> Plot? {
        return waveformWithIdentifier(waveformDataSource.identifier + "." + "AudioMaxValueLogicProvider")
    }
    
    func avgValuesWaveform() -> Plot? {
        return waveformWithIdentifier(waveformDataSource.identifier + "." + "AudioAverageValueLogicProvider")
    }

    //MARK: -
    //MARK: - Reading
    func readAndDrawSynchronously(_ completion: @escaping  (Bool, NSError?) -> ()) {
        
        if self.samplesReader == nil {
            completion(false, NSError(domain: "",code: -1, userInfo: nil))
            return
        }
        
        self.diagram?.waveformDiagramView.startSynchingWithDataSource()
        let date = NSDate()
        
        self.samplesReader?.readAudioFormat {
            [weak self] (format, error) in
        
            guard let _ = format else {
                completion(false, NSError(domain: "DVGWaveform", code: -1, userInfo: nil))
                self?.diagram?.waveformDiagramView.stopSynchingWithDataSource()
                return
            }
        
            self?.samplesReader?.readSamples(completion: { (error) in
                if error == nil {
                    completion(true, nil)
                } else {
                    completion(false, NSError(domain: "DVGWaveform", code: -1, userInfo: nil))
                }
                print("time: \(-date.timeIntervalSinceNow)")
            })
        }
    }
    
    public func addDataSource(_ dataSource: ChannelSource) {
        
        channelSourceMapper.addChannelSource(dataSource)
        self.diagramViewModel.channelsSource = channelSourceMapper
        
        // Set plot model to plot view
        diagram?.delegate = diagramViewModel
        diagram?.dataSource = diagramViewModel
        
        diagramViewModel.movementsDelegate = self
    }
    
    //MARK: -
    //MARK: - Private vars

    fileprivate var diagram: DVGAudioWaveformDiagram?
    fileprivate var diagramViewModel = DVGAudioWaveformDiagramModel()
    fileprivate var samplesReader: AudioSamplesReader?
    fileprivate var waveformDataSource = ScalableChannelsContainer()
    fileprivate var channelSourceMapper = ChannelSourceMapper()
    
    //MARK: - Public vars
    weak var movementDelegate: DVGDiagramMovementsDelegate?
    var asset: AVAsset? {
        didSet {
            if let asset = asset {
                self.samplesReader = AudioSamplesReader(asset: asset)
                self.configure()
                self.samplesReader?.samplesHandler = waveformDataSource
            }
        }
    }
    var numberOfPointsOnThePlot = 512 {
        didSet {
            waveformDataSource.neededSamplesCount = numberOfPointsOnThePlot
        }
    }
    var start: CGFloat = 0.0
    var scale: CGFloat = 1.0
    
    @objc var playbackRelativePosition: NSNumber? {
        get { return self._playbackRelativePosition as NSNumber? }
        set { self._playbackRelativePosition = newValue == nil ? nil : CGFloat(newValue!) }
    }
    
    var _playbackRelativePosition: CGFloat? {
        get { return self.diagram?.playbackRelativePosition }
        set { self.diagram?.playbackRelativePosition = newValue }
    }
    
    var progress: Progress? {
        return self.samplesReader?.progress
    }
}

////MARK: - DiagramViewModelDelegate
extension DVGWaveformController: DVGDiagramMovementsDelegate {
    func diagramDidSelect(_ dataRange: DataRange) {
        self.movementDelegate?.diagramDidSelect(dataRange)
    }
    func diagramMoved(scale: Double, start: Double) {
        self.waveformDataSource.reset(DataRange(location: start, length: 1/scale))
        self.movementDelegate?.diagramMoved(scale: scale, start: start)
    }
}
