//
//  DVGDiagram.swift
//  Waveform
//
//  Created by developer on 26/01/16.
//  Copyright © 2016 developer. All rights reserved.
//

import UIKit

@objc
public
class DVGAudioWaveformDiagram: UIView {
    
    //MARK: - Properties
    var panToSelect: UIPanGestureRecognizer!
    var pan: UIPanGestureRecognizer!
    var pinch: UIPinchGestureRecognizer!
    
    var selectionView: SelectionView!
    var playbackPositionView: PlaybackPositionView!
    var waveformDiagramView: Diagram!
    
    weak var delegate: DVGDiagramDelegate? {
        didSet {
            waveformDiagramView.delegate = delegate
        }
    }
    weak var dataSource: DiagramDataSource? {
        didSet {
            waveformDiagramView.dataSource = dataSource
        }
    }
    
    //MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    func setup(){
        self.setupAudioWaveformView()
        self.setupGestures()
        self.setupSelectionView()
        self.setupPlaybackPositionView()
    }
    
    func setupAudioWaveformView() {
        let waveformDiagramView = Diagram()
        addSubview(waveformDiagramView)
        waveformDiagramView.translatesAutoresizingMaskIntoConstraints = false
        waveformDiagramView.attachBoundsOfSuperview()
        self.waveformDiagramView = waveformDiagramView
    }
    
    func setupGestures() {
        // New gestures
        let panToSelect                    = UIPanGestureRecognizer(target: self, action: #selector(DVGAudioWaveformDiagram.handlePanToSelect(_:)))
        panToSelect.delegate               = self
        self.addGestureRecognizer(panToSelect)
        self.panToSelect                   = panToSelect
        panToSelect.maximumNumberOfTouches = 1

        let pinch                   = UIPinchGestureRecognizer(target: self, action: #selector(DVGAudioWaveformDiagram.handlePinch(_:)))
        pinch.delegate              = self
        self.addGestureRecognizer(pinch)
        self.pinch                  = pinch
        
        let pan                         = UIPanGestureRecognizer(target: self, action: #selector(DVGAudioWaveformDiagram.handlePan(_:)))
        self.addGestureRecognizer(pan)
        self.pan                        = pan
        self.pan.minimumNumberOfTouches = 2
    }
    
    func setupSelectionView() {
        let selectionView = SelectionView()
        self.addSubview(selectionView)
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.attachBoundsOfSuperview()
        self.selectionView = selectionView
    }
    
    func setupPlaybackPositionView() {
        let playbackPositionView = PlaybackPositionView()
        self.addSubview(playbackPositionView)
        playbackPositionView.translatesAutoresizingMaskIntoConstraints = false
        playbackPositionView.attachBoundsOfSuperview()
        self.playbackPositionView = playbackPositionView
    }
    
    
    //MARK: - Gestures
    private var panStartLocation: CGFloat?
    private var panStartVelocityX: CGFloat?
    
    var delayedTask : DispatchWorkItem?
    
    private var selectionUI : DataRange? {
        if selection == nil {
            return nil
        }
        
        let convertedSelection = selection?.convertToGeometry(dataSource!.geometry)
        
        return DataRange(location: convertedSelection!.location * bounds.width.double ,
                           length: convertedSelection!.length * bounds.width.double)
    }
    private var startSelection: DataRange?
    
    enum PanAction {
        case moving, moveLeftSlider, moveRightSlider, selectNewArea
    }
    private var action: PanAction?

    
    func handlePanToSelect(_ pan: UIPanGestureRecognizer) {
        
        switch pan.state {
        case .began:
            
            if self.panStartLocation == nil {
                self.panStartLocation = pan.location(in: self).x
                self.panStartVelocityX = pan.velocity(in: self).x
            }
            
            if (selectionUI == nil){
                self.configureSelectionFromPosition(panStartLocation!,
                                                    toPosition: pan.location(in: self).x,
                                                    anchor: panStartVelocityX!.double < 0.0 ? .right : .left )
                action = .selectNewArea
            } else if selectionUI!.length >= minSelectionWidth.double - 1 {
                
                let sliderHalfWidth = 20.0
                
                let letftSliderRange = (selectionUI!.location - sliderHalfWidth)..<(selectionUI!.location + sliderHalfWidth)
                if letftSliderRange.contains(panStartLocation!.double) {
                    action = .moveLeftSlider
                }
                
                let righSliderRange = (selectionUI!.location + selectionUI!.length - sliderHalfWidth)..<(selectionUI!.location + selectionUI!.length + sliderHalfWidth)
                if righSliderRange.contains(panStartLocation!.double) {
                    action = .moveRightSlider
                }
                
                let middleRange = letftSliderRange.upperBound..<righSliderRange.lowerBound
                if middleRange.contains(panStartLocation!.double){
                    action = .moving
                }
            } else {
                let range = selectionUI!.location..<(selectionUI!.location + selectionUI!.length)
                if range.contains(panStartLocation!.double) {
                    action = .moving
                } else {
                    self.configureSelectionFromPosition(panStartLocation!,
                                                        toPosition: pan.location(in: self).x,
                                                        anchor: pan.velocity(in: self).x < 0 ? .right : .left)
                    action = .selectNewArea
                }
            }
            
            startSelection = selectionUI
            
            break
        case .failed:
            print("pan failed")
        case .ended:
            // notify delegate
            self.panStartLocation = nil
            if let selection = self.selection {
                
                if delayedTask != nil {
                    delayedTask!.cancel()
                }
                
                delayedTask = DispatchWorkItem { [weak self] in
                    self?.delegate?.diagramDidSelect(selection)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: delayedTask!)
            }
            action = nil
            break
        case .changed:
            
            if action == nil {
                self.configureSelectionFromPosition(panStartLocation!,
                                                    toPosition: pan.location(in: self).x,
                                                    anchor: panStartVelocityX!.double < 0.0 ? .right : .left)
            } else {
                let delta =  panStartLocation! - pan.location(in: self).x
                
                switch action! {
                    
                case .moving:
                    print("Moving !")
                    print("selection location:\(startSelection!.location) length:\(startSelection!.length)")
                    print("delta: \(delta)")
                    let start = startSelection!.location.cgfloat - delta
                    let end = start + startSelection!.length.cgfloat
                    print("Move start: \(start) end: \(end)")
                    self.configureSelectionFromPosition(start, toPosition: end, anchor: .left)
                    break
                    
                case .moveLeftSlider:
                    print("Moving left slider!")
                    print("selection location:\(startSelection!.location) length:\(startSelection!.length)")
                    print("delta: \(delta)")
                    let start = startSelection!.location + startSelection!.length
                    let end = pan.location(in: self).x
                    print("Move start: \(start) end: \(end)")
                    self.configureSelectionFromPosition(start.cgfloat, toPosition: end, anchor: .right)
                    break
                    
                case .moveRightSlider:
                    print("Moving right slider!")
                    let location = startSelection!.location.cgfloat + startSelection!.length.cgfloat - delta
                    self.configureSelectionFromPosition(startSelection!.location.cgfloat, toPosition: location, anchor: .left)
                    break
                    
                case .selectNewArea:
                    print("Selecting new area!")
                    self.configureSelectionFromPosition(panStartLocation!,
                                                        toPosition: pan.location(in: self).x,
                                                        anchor: panStartVelocityX!.double < 0.0 ? .right : .left)
                    break
                }
            }

        default:
            break
        }
    }
    
    
    
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        self.selectionView.selection = nil
        
        let k = self.playbackRelativePosition
        self.playbackRelativePosition = k
        
        let l = self.selection
        self.selection = l
        
        switch gesture.state {
        case .changed:
            let scale     = gesture.scale
            let locationX = gesture.location(in: gesture.view).x
            let relativeLocation = locationX/gesture.view!.bounds.width
            self.delegate?.zoomAt(relativeLocation, relativeScale: scale)
            gesture.scale = 1.0
        case .ended:
            print(self.dataSource?.geometry )
        default:()
        }
    }
    
    
    
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        self.selectionView.selection = nil
        switch gesture.state {
        case .changed:
            let deltaX         = gesture.translation(in: gesture.view).x
            let relativeDeltaX = deltaX/gesture.view!.bounds.width
            self.delegate?.moveByDistance(relativeDeltaX)
            gesture.setTranslation(.zero, in: gesture.view)
        default:()
        }
        
        let k = self.playbackRelativePosition
        self.playbackRelativePosition = k
        
        let l = self.selection
        self.selection = l
    }
    
    
    
    var minSelectionWidth: CGFloat = 50.0
    var playbackRelativePosition: CGFloat? = nil {
        didSet {
            if let playbackRelativePosition = playbackRelativePosition,
                let viewModel = self.dataSource {
                self.playbackPositionView.position = playbackRelativePosition.convertToGeometry(viewModel.geometry)
            } else {
                self.playbackPositionView.position = nil
            }
        }
    }
    var selection: DataRange? = nil {
        didSet {
            if let relativeSelection = selection,
                let viewModel = self.dataSource {
                self.selectionView.selection = relativeSelection.convertToGeometry(viewModel.geometry)
            } else {
                self.selectionView.selection = nil
            }
        }
    }
    
    enum Anchor {
        case left, right
    }
    
    func configureSelectionFromPosition(_ _startPosition: CGFloat, toPosition _endPosition: CGFloat, anchor: Anchor) {
    
        //TODO: move geometry logic to viewModel (create it first)
        var startPosition = min(_endPosition, _startPosition)
        var endPosition   = max(_endPosition, _startPosition)
        
        
        //pan left slider anchor - right
        switch anchor {
            
        case .right:
            if _startPosition > _endPosition && abs(endPosition - startPosition) < minSelectionWidth {
                startPosition = endPosition - minSelectionWidth
            }
            if _startPosition <= _endPosition {
                startPosition = startPosition - minSelectionWidth
            }
            break
            
        case .left:
            if _startPosition < _endPosition && abs(endPosition - startPosition) < minSelectionWidth {
                endPosition = startPosition + minSelectionWidth
            }
            if _startPosition >= _endPosition {
                endPosition = endPosition + minSelectionWidth
            }
            break
        }
        startPosition = max(0, startPosition)
        endPosition   = min(endPosition, self.bounds.width)
        
        let width = endPosition - startPosition
        
        let range = DataRange(
            location: Double(startPosition / self.bounds.width),
            length:   Double(width / self.bounds.width))

        self.selection = range.convertFromGeometry(self.dataSource!.geometry)
    }
    
}

extension DVGAudioWaveformDiagram: UIGestureRecognizerDelegate {
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
            return false
    }
    
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
