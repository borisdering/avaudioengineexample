//
//  ViewController.swift
//  AVAudioEngineExample
//
//  Created by Boris Dering on 30.09.19.
//  Copyright © 2019 Boris Dering. All rights reserved.
//

import UIKit
import AVKit

extension AVAudioPCMBuffer {
    static func create(from sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {

        guard let description: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
            let sampleRate: Float64 = description.audioStreamBasicDescription?.mSampleRate,
            let numberOfChannels: Int = description.audioChannelLayout?.numberOfChannels
            else { return nil }

        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?

        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: nil, bufferListOut: &audioBufferList, bufferListSize: MemoryLayout<AudioBufferList>.size, blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: 0, blockBufferOut: &blockBuffer)

        guard blockBuffer != nil else { return nil }

        let length: Int = CMBlockBufferGetDataLength(blockBuffer!)

        guard let layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Stereo) else { return nil }
        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt32, sampleRate: sampleRate, interleaved: false, channelLayout: layout)

        let audioBufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        audioBufferListPointer.pointee = audioBufferList

        return AVAudioPCMBufferCreate(audioFormat, audioBufferListPointer, AVAudioFrameCount(length))
    }
}

struct RealtimeReader {
    
    var player: AVAudioPlayerNode
    
    init() {
        self.player = AVAudioPlayerNode()
    }
    
    func schedule(url: URL) {
        
        let asset = AVAsset(url: url)
        let reader = try! AVAssetReader(asset: asset)
        
        let audiotrack = asset.tracks(withMediaType: .audio).first
        let audioOutput = AVAssetReaderTrackOutput(track: audiotrack!, outputSettings: [AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM)])
        reader.add(audioOutput)
        
        reader.startReading()
        
        while let sampleBuffer = audioOutput.copyNextSampleBuffer() {
            
            // trying to convert the sample buffer to a pcm buffer
            // so that the audio engine understands it...
            guard let buffer = AVAudioPCMBuffer.create(from: sampleBuffer) else { return }
        }
    }
}

struct AudioEngine {
    
    private var engine: AVAudioEngine
    private var mainMixer: AVAudioMixerNode
    private var playerMixer: AVAudioMixerNode
    
    private var reader: RealtimeReader
    
    private var file: AVAudioFile?
    var recordingURL: URL?
    let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    init() {
        self.engine = AVAudioEngine()
        self.mainMixer = AVAudioMixerNode()
        self.playerMixer = AVAudioMixerNode()
        self.reader = RealtimeReader()
    }
    
    mutating func start() {
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
        try! AVAudioSession.sharedInstance().setActive(true)
        
        let format = self.engine.mainMixerNode.inputFormat(forBus: 0)
        
        self.engine.attach(reader.player)
        self.engine.connect(reader.player, to:  self.engine.mainMixerNode, format: format)
        
        self.engine.prepare()
        try! self.engine.start()
        
        // here you can choose between silence or a usual mp3 file.
//        self.reader.schedule(url: Bundle.main.url(forResource: "silence", withExtension: "mp3")!)
        self.reader.schedule(url: Bundle.main.url(forResource: "example", withExtension: "mp3")!)
    }
    
    mutating func play() {
        self.reader.player.play()
    }
    
    mutating func stop() {
        self.reader.player.stop()
    }
}

class ViewController: UIViewController {

    var engine = AudioEngine()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Play", for: UIControl.State.normal)
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(handlePlayButtonTapped), for: UIControl.Event.touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.engine.start()
        
        self.view.addSubview(self.playButton)
        self.playButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.playButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.playButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        self.playButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    @objc private func handlePlayButtonTapped() {
        guard !self.engine.isPlaying else {
            self.engine.stop()
            return
        }
        self.engine.play()
    }
}
