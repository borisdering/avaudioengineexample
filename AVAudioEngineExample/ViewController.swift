//
//  ViewController.swift
//  AVAudioEngineExample
//
//  Created by Boris Dering on 30.09.19.
//  Copyright © 2019 Boris Dering. All rights reserved.
//

import UIKit
import AVKit

struct AudioEngine {
    
    private var engine: AVAudioEngine
    private var mainMixer: AVAudioMixerNode
    private var playerMixer: AVAudioMixerNode
    private var micMixer: AVAudioMixerNode
    private var player: AVAudioPlayerNode
    private var player2: AVAudioPlayerNode
    
    private var file: AVAudioFile?
    var recordingURL: URL?
    let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: 44 * 1000,
        AVNumberOfChannelsKey: 2
    ]
    
    var settings2 = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
//    let formatConverter: AVAudioConverter
    
    var isPlaying: Bool = false
    var isRecording: Bool = false
    
    init() {
        self.engine = AVAudioEngine()
        self.mainMixer = AVAudioMixerNode()
        self.playerMixer = AVAudioMixerNode()
        self.micMixer = AVAudioMixerNode()
        self.player = AVAudioPlayerNode()
        self.player2 = AVAudioPlayerNode()
        
//        let destinationFormat = AVAudioFormat()
//        self.formatConverter = AVAudioConverter(from: self.engine.inputNode.inputFormat(forBus: 0), to: <#T##AVAudioFormat#>)
    }
    
    mutating func start() {
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
        try! AVAudioSession.sharedInstance().setActive(true)
        
        let input = self.engine.inputNode
        let format = input.inputFormat(forBus: 0)
        
        self.engine.attach(self.mainMixer)
        self.engine.attach(self.player)
        self.engine.attach(self.micMixer)
        self.engine.attach(self.player2)
        
        self.engine.connect(self.mainMixer, to: self.engine.outputNode, format: format)
//        self.engine.connect(self.micMixer, to: self.mainMixer, format: format)
        self.engine.connect(self.player, to: self.mainMixer, format: format)
        self.engine.connect(self.player, to: self.micMixer, format: format)
        
        let micInput = self.engine.inputNode
        self.engine.connect(micInput, to: self.micMixer, format: format)
        
        self.engine.prepare()
        do {
            try self.engine.start()
        } catch {
            debugPrint(error)
            fatalError()
        }
        
        print("Did setup audio engine successfully...")
    }
    
    mutating func play(file url: URL) {
        let file = try! AVAudioFile(forReading: url)
        self.player.scheduleFile(file, at: nil, completionHandler: nil)
        self.player.play(at: nil)
        self.isPlaying = true
        print("Did start playback...")
    }
    
    mutating func startRecording() {
        self.isRecording = true
        let url = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!.appendingPathComponent("sample.caf")
        try! FileManager.default.removeItem(atPath: url.path)
        guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil) else { fatalError("Unable to create file...") }
        self.recordingURL = url
        do {
            self.file = try AVAudioFile(forWriting: url, settings: self.mainMixer.outputFormat(forBus: 0).settings)
        } catch {
            debugPrint(error)
            fatalError("Unable to create audio file to write to with error...")
        }
        
        self.micMixer.installTap(onBus: 0, bufferSize: 4096, format: self.mainMixer.outputFormat(forBus: 0)) { [self] (buffer: AVAudioPCMBuffer, time) in

            do {
                try self.file?.write(from: buffer)
            } catch {
                debugPrint(error)
            }
        }
        
        print("Did start recording...")
    }
    
    mutating func stopRecording() {
        self.isRecording = false
        self.file = nil
        self.micMixer.removeTap(onBus: 0)
        print("Did finish recording...")
        self.engine.stop()
    }
    
    mutating func stop() {
        self.player.stop()
        self.isPlaying = false
        print("Did stop playback...")
    }
}

class ViewController: UIViewController {

    var engine = AudioEngine()
    
    lazy var recordButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Record", for: UIControl.State.normal)
        button.backgroundColor = UIColor.green
        button.addTarget(self, action: #selector(handleRecordButtonTapped), for: UIControl.Event.touchUpInside)
        
        return button
    }()
    
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
        
        self.view.addSubview(self.recordButton)
        self.recordButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.recordButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.recordButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        self.recordButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        self.view.addSubview(self.playButton)
        self.playButton.topAnchor.constraint(equalTo: self.recordButton.bottomAnchor, constant: 0).isActive = true
        self.playButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.playButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        self.playButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    @objc private func handleRecordButtonTapped() {
        if !self.engine.isRecording {
            self.engine.startRecording()
        } else {
            self.engine.stop()
            
            self.show()
        }
    }
    
    @objc private func handlePlayButtonTapped() {
        guard !self.engine.isPlaying else {
            self.engine.stop()
            return
        }
        self.engine.play(file: Bundle.main.url(forResource: "example", withExtension: "mp4")!)
    }
    
    private func show() {
        guard let url = self.engine.recordingURL else { return }
        
        print(url)
        print(FileManager.default.fileExists(atPath: url.path))
        
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        self.present(controller, animated: true, completion: nil)
    }
}

