//
//  DiagramView.swift
//  Waveform
//
//  Created by developer on 22/12/15.
//  Copyright © 2015 developer. All rights reserved.
//

import UIKit.UIView

protocol PlotDataSource: class {
    var identifier: String { get }
    var dataSourceFrame: CGRect { get }
    var pointsCount: Int { get }
    var needsRedraw: Bool { get set }
    func updateGeometry()
    func pointAtIndex(_ index: Int) -> CGPoint
}

protocol DiagramDataSource: class {
    var geometry: DiagramGeometry { get }
    var onPlotUpdate: () -> () { get set }
    var plotDataSourcesCount: Int { get }
    func plotDataSourceAtIndex(_ index: Int) -> PlotDataSource
}

protocol DiagramDelegate: class {
    func zoomAt(_ zoomAreaCenter: CGFloat, relativeScale: CGFloat)
    func moveByDistance(_ relativeDeltaX: CGFloat)
}

protocol DVGDiagramDelegate: class, DiagramDelegate {
    func diagramDidSelect(_ dataRange: DataRange)
}

protocol ChannelSource: class {
    var channelsCount: Int { get }
    var onChannelsChanged: () -> () { get set }
    func channelAtIndex(_ index: Int) -> Channel
}

protocol AbstractChannel: class, Identifiable {
    var totalCount: Int { get }
    var count: Int { get }
    var identifier: String { get }
    var maxValue: Double { get }
    var minValue: Double { get }
    
    subscript(index: Int) -> Double { get }
    func handleValue<U: NumberType>(_ value: U)
}

protocol AudioSamplesHandler: class {
    func willStartReadSamples(estimatedSampleCount: Int)
    func didStopReadSamples(count: Int)
    func handleSamples(_ samplesContainer: AudioSamplesContainer)
}

extension AudioSamplesHandler {
    func handleSamples(buffer: UnsafePointer<Int16>, bufferLength: Int, numberOfChannels: Int) {
        return self.handleSamples(AudioSamplesContainer.init(buffer: buffer, length: bufferLength, numberOfChannels: numberOfChannels))
    }
}

protocol Identifiable {
    var identifier: String { get }
}
